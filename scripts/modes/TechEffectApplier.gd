class_name TechEffectApplier
extends Node
## Turns a Tech rule's {type, params} into an actual gameplay change,
## applied once (at the moment the rule activates) to the current player
## roster / storm / loot spawner. Rules are cumulative and never expire, so
## this only ever adds effects -- it's called once per newly-activated rule.

var world: WorldGenerator
var loot_spawner: LootSpawner
var storm: StormManager
var players: Array[Node3D] = []

# Continuous / periodic effects accumulate here so _process can drive them.
var hazard_ground_dps: float = 0.0
var hazard_exposed_dps: float = 0.0
var periodic_timers: Dictionary = {}
var reflect_damage_pct: float = 0.0
var damage_cap: float = INF

func setup(world_node: WorldGenerator, loot_node: LootSpawner, storm_node: StormManager, player_list: Array[Node3D]) -> void:
	world = world_node
	loot_spawner = loot_node
	storm = storm_node
	players = player_list

func apply(rule: Dictionary) -> void:
	var effect: Dictionary = rule.effect
	var type: String = effect.type
	var p: Dictionary = effect.params
	match type:
		"gravity_scale":
			ProjectSettings.set_setting("physics/3d/default_gravity", 20.0 * p.scale)
		"grant_double_jump":
			for pl in players:
				pl.grant_double_jump(p.get("extra_jumps", 1))
		"disable_jump":
			for pl in players:
				pl.set_jump_enabled(false)
		"disable_build":
			for pl in players:
				pl.set_build_enabled(false)
		"infinite_sprint", "infinite_sprint_boost":
			pass # handled by SPRINT_SPEED being uncapped; flavor rule
		"speed_scale":
			for pl in players:
				pl.set_speed_multiplier(pl.speed_multiplier * p.scale)
		"grant_grapple", "grant_jetpack":
			pass # traversal grant is tracked via rule tags for compatibility;
				 # a full grapple/jetpack ability would hook PlayerAbilities here.
		"disable_fall_damage", "disable_fall_damage_boost":
			pass # Player's simplified movement doesn't apply fall damage yet.
		"periodic_teleport":
			periodic_timers["teleport"] = {"interval": p.interval, "t": p.interval}
		"scale_players":
			for pl in players:
				pl.scale = Vector3.ONE * p.scale
				pl.max_health *= p.get("hp_mult", 1.0)
				pl.health *= p.get("hp_mult", 1.0)
				pl.set_speed_multiplier(pl.speed_multiplier * p.get("speed_mult", 1.0))
		"hazard_ground":
			hazard_ground_dps += p.dps
		"hazard_exposed":
			hazard_exposed_dps += p.dps
		"storm_speed_scale":
			storm.speed_scale *= p.scale
		"invert_storm":
			storm.inverted = true
		"explosive_death":
			pass # BattleRoyaleMode/TechBattleMode connects Player.died to this via _on_player_died
		"periodic_meteors":
			periodic_timers["meteors"] = {"interval": p.interval, "t": p.interval, "damage": p.damage, "radius": p.radius}
		"set_hp":
			for pl in players:
				pl.max_health = p.hp
				pl.health = p.hp
		"reflect_damage":
			reflect_damage_pct += p.pct
		"damage_scale":
			for pl in players:
				pl.set_damage_dealt_multiplier(pl.damage_dealt_multiplier * p.scale)
		"damage_taken_scale":
			for pl in players:
				pl.set_damage_taken_multiplier(pl.damage_taken_multiplier * p.scale)
		"fire_rate_scale", "infinite_ammo", "infinite_ammo_and_rate", "crit_chance", \
		"knockback_scale", "evolve_rate_scale", "apply_bleed_on_hit", "headshot_lethal":
			pass # combat-modifier rules; hook point for WeaponBase.try_use()/hitscan_from_player
		"damage_cap":
			damage_cap = min(damage_cap, p.cap)
		"hp_regen":
			periodic_timers["regen_%s" % rule.id] = {"interval": 1.0, "t": 1.0, "amount": p.rate}
		"heal_effect_scale", "disable_heal_items", "disable_all_healing", "overheal":
			pass # healing-item hook point (item-use pipeline not modeled at this layer)
		"lifesteal_all":
			pass # applied inside WeaponBase.hitscan_from_player via owner_player lookup
		"periodic_heal_pulse":
			periodic_timers["heal_pulse"] = {"interval": p.interval, "t": p.interval, "amount": p.amount}
		"loot_magnet":
			pass # loot-pickup radius hook point
		"loot_density_scale":
			loot_spawner.density_multiplier *= p.scale
		"disable_loot_spawns":
			loot_spawner.enabled = false
		"periodic_reveal", "footstep_range_scale", "invisible_when_still", \
		"random_weapon_on_kill", "friendly_fire", "force_camera_mode", \
		"reveal_chests", "shuffle_weapons_once", "periodic_gravity_flip", \
		"daynight_speed_scale", "fog_density_scale", "wind_gusts", \
		"periodic_earthquake", "enable_revive", "enable_last_stand", \
		"shield_regen", "grant_shield", "disable_shield_regen", "growth_on_kill":
			pass # cosmetic / peripheral systems -- safe no-ops offline, ready
				 # for HUD/UI or a future ability system to hook into
		"spawn_supply_drop":
			_spawn_supply_drops(p.get("count", 1))
		_:
			push_warning("TechEffectApplier: unhandled effect type '%s'" % type)

func _spawn_supply_drops(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var angle := rng.randf_range(0, TAU)
		var dist := rng.randf_range(0, storm.current_radius * 0.8)
		var pos := Vector3(storm.current_center.x + cos(angle) * dist, 0.6, storm.current_center.y + sin(angle) * dist)
		var pickup := WeaponPickup.new()
		pickup.setup(WeaponDatabase.random_floor_loot_id(rng))
		loot_spawner.add_child(pickup)
		pickup.global_position = pos

func process_periodics(delta: float) -> void:
	if hazard_ground_dps > 0.0 or hazard_exposed_dps > 0.0:
		for pl in players:
			if is_instance_valid(pl) and pl.alive and pl.is_on_floor():
				pl.take_damage((hazard_ground_dps + hazard_exposed_dps) * delta, null)
	for key in periodic_timers.keys():
		var timer: Dictionary = periodic_timers[key]
		timer.t -= delta
		if timer.t <= 0.0:
			timer.t = timer.interval
			_fire_periodic(key, timer)
		periodic_timers[key] = timer

func _fire_periodic(key: String, timer: Dictionary) -> void:
	if key == "teleport":
		for pl in players:
			if is_instance_valid(pl) and pl.alive:
				var angle := randf_range(0, TAU)
				var dist := randf_range(0, storm.current_radius * 0.7)
				pl.global_position = Vector3(storm.current_center.x + cos(angle) * dist, 3.0, storm.current_center.y + sin(angle) * dist)
	elif key == "meteors":
		for pl in players:
			if is_instance_valid(pl) and pl.alive and randf() < 0.3:
				pl.take_damage(timer.damage, null)
	elif key == "heal_pulse":
		for pl in players:
			if is_instance_valid(pl) and pl.alive:
				pl.heal(timer.amount)
	elif key.begins_with("regen_"):
		for pl in players:
			if is_instance_valid(pl) and pl.alive:
				pl.heal(timer.amount)
