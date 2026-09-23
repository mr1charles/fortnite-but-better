class_name WeaponBase
extends Node
## Base class every held weapon / activatable item script extends.
##
## An instance is created at runtime from a WeaponDatabase entry (see
## Player.gd -> equip_weapon) and attached under the player. Subclasses in
## weapons_impl/ override `primary_use()` and, where relevant, `tick()`.

signal fired()
signal hit_target(target: Node, damage: float)

var def: Dictionary = {}
var owner_player: Node3D
var cooldown_remaining: float = 0.0
var ammo_in_mag: int = 0
var reloading: bool = false
var reload_timer: float = 0.0

func setup(weapon_def: Dictionary, player: Node3D) -> void:
	def = weapon_def
	owner_player = player
	ammo_in_mag = def.get("mag_size", 1)

func get_anim_state() -> String:
	return def.get("anim_state", "idle")

func tick(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining -= delta
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			reloading = false
			ammo_in_mag = def.get("mag_size", 1)

func try_use() -> bool:
	if cooldown_remaining > 0.0 or reloading:
		return false
	if def.has("mag_size") and ammo_in_mag <= 0:
		start_reload()
		return false
	cooldown_remaining = def.get("fire_rate", 0.3)
	if def.has("mag_size"):
		ammo_in_mag -= 1
	primary_use()
	emit_signal("fired")
	return true

func start_reload() -> void:
	if reloading or def.get("mag_size", 0) <= 0:
		return
	reloading = true
	reload_timer = def.get("reload_time", 2.0)

## Override in subclasses.
func primary_use() -> void:
	pass

## Hitscan helper shared by most weapons: raycasts from the player's camera
## and applies damage + on_hit_effects to whatever it strikes.
func hitscan_from_player(damage: float, max_range: float, spread_deg: float = 0.0) -> Dictionary:
	if owner_player == null or not owner_player.has_method("get_aim_ray"):
		return {}
	var origin: Vector3 = owner_player.get_aim_origin()
	var dir: Vector3 = owner_player.get_aim_direction()
	if spread_deg > 0.0:
		dir = _apply_spread(dir, spread_deg)
	var space_state := owner_player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * max_range)
	query.exclude = [owner_player.get_rid()]
	var result := space_state.intersect_ray(query)
	if result and result.has("collider"):
		var target = result.collider
		if target.has_method("take_damage"):
			target.take_damage(damage, owner_player)
			emit_signal("hit_target", target, damage)
	return result

func _apply_spread(dir: Vector3, spread_deg: float) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var yaw := deg_to_rad(rng.randf_range(-spread_deg, spread_deg))
	var pitch := deg_to_rad(rng.randf_range(-spread_deg, spread_deg))
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	return (basis * dir).normalized()
