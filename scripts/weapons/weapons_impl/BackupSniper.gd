class_name BackupSniper
extends WeaponBase
## Retribution Rig: rides on the player's back and isn't manually fired. Any
## time the player takes damage, it lines up on the attacker and fires back
## automatically after a short reaction delay, on its own cooldown.

var _cooldown: float = 0.0
var _pending_attacker: Node3D = null
var _pending_timer: float = 0.0

func setup(weapon_def: Dictionary, player: Node3D) -> void:
	super.setup(weapon_def, player)
	if player.has_signal("took_damage"):
		player.took_damage.connect(_on_player_took_damage)

func tick(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _pending_attacker != null:
		_pending_timer -= delta
		if _pending_timer <= 0.0:
			_fire_at(_pending_attacker)
			_pending_attacker = null

func _on_player_took_damage(_amount: float, attacker: Node3D) -> void:
	if _cooldown > 0.0 or attacker == null or not is_instance_valid(attacker):
		return
	_pending_attacker = attacker
	_pending_timer = def.get("reaction_delay", 0.35)

func _fire_at(attacker: Node3D) -> void:
	if not is_instance_valid(attacker):
		return
	_cooldown = def.get("trigger_cooldown", 6.0)
	var dist: float = owner_player.global_position.distance_to(attacker.global_position)
	if dist > def.get("range", 150.0):
		return
	var space_state := owner_player.get_world_3d().direct_space_state
	var from: Vector3 = owner_player.global_position + Vector3.UP
	var to: Vector3 = attacker.global_position + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [owner_player.get_rid()]
	var result := space_state.intersect_ray(query)
	if result.is_empty() or result.collider == attacker:
		if attacker.has_method("take_damage"):
			attacker.take_damage(def.get("damage", 55.0), owner_player)
			emit_signal("hit_target", attacker, def.get("damage", 55.0))
	emit_signal("fired")
