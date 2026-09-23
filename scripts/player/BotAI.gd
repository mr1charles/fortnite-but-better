class_name BotAI
extends Node
## Deliberately simple offline bot: wanders toward a random nearby point,
## and if an enemy is within sight range, turns to face them and fires.
## This exists so Battle Royale / Tech Battle aren't a 1-player sandbox
## offline -- it is not meant to be a serious opponent AI.

const SIGHT_RANGE := 45.0
const REPICK_INTERVAL := 6.0

@export var player: Player

var _wander_target: Vector3 = Vector3.ZERO
var _repick_timer: float = 0.0
var _fire_cooldown: float = 0.0

func _ready() -> void:
	player.is_bot = true
	_repick_wander_target()

func _physics_process(delta: float) -> void:
	if not player.alive:
		return
	_repick_timer -= delta
	if _repick_timer <= 0.0:
		_repick_wander_target()

	var enemy := _find_nearest_enemy()
	if enemy:
		var to_enemy: Vector3 = (enemy.global_position - player.global_position)
		player.bot_aim_direction = to_enemy.normalized()
		player.bot_input_dir = Vector2(0, -1) if to_enemy.length() > 6.0 else Vector2.ZERO
		_fire_cooldown -= delta
		if _fire_cooldown <= 0.0 and to_enemy.length() <= SIGHT_RANGE:
			player.use_active_weapon()
			_fire_cooldown = 0.6
		_face_direction(to_enemy)
	else:
		var to_target: Vector3 = _wander_target - player.global_position
		if to_target.length() > 2.0:
			player.bot_input_dir = Vector2(0, -1)
			player.bot_aim_direction = to_target.normalized()
			_face_direction(to_target)
		else:
			player.bot_input_dir = Vector2.ZERO

func _face_direction(dir: Vector3) -> void:
	if dir.length() < 0.01:
		return
	var flat := Vector3(dir.x, 0, dir.z)
	if flat.length() > 0.01:
		player.look_at(player.global_position + flat, Vector3.UP)

func _repick_wander_target() -> void:
	_repick_timer = REPICK_INTERVAL
	var angle := randf_range(0, TAU)
	var dist := randf_range(10, 40)
	_wander_target = player.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _find_nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_dist := SIGHT_RANGE
	for p in player.get_tree().get_nodes_in_group("players"):
		if p == player or not p.alive:
			continue
		var d: float = player.global_position.distance_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best = p
	return best
