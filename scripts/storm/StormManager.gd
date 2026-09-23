class_name StormManager
extends Node3D
## Drives the shrinking circle. For the first CALM_PHASE_SECONDS nothing
## happens environmentally (per the design brief); after that the storm
## begins closing in through numbered phases. Every time a phase completes
## (the circle finishes shrinking and pauses before the next shrink), this
## emits `phase_advanced` -- which is what TechBattleMode listens to in
## order to bring in one more Tech rule per phase.

signal calm_phase_ended()
signal phase_advanced(phase_index: int)
signal circle_updated(center: Vector2, radius: float)

const CALM_PHASE_SECONDS := 45.0
const PHASE_SHRINK_TIME := 45.0
const PHASE_WAIT_TIME := 20.0
const STORM_DAMAGE_PER_SEC := 2.0

var speed_scale: float = 1.0
var inverted: bool = false # storm_heals Tech rule

var current_center: Vector2 = Vector2.ZERO
var current_radius: float = WorldGenerator.ISLAND_RADIUS
var _next_center: Vector2
var _next_radius: float

var _phase_index: int = -1
var _state_timer: float = 0.0
var _shrinking: bool = false
var _players: Array[Node3D] = []
var _phase_start_center: Vector2 = Vector2.ZERO
var _phase_start_radius: float = WorldGenerator.ISLAND_RADIUS

func _ready() -> void:
	current_radius = WorldGenerator.ISLAND_RADIUS
	_next_radius = current_radius
	_state_timer = CALM_PHASE_SECONDS

func register_players(players: Array[Node3D]) -> void:
	_players = players

func _process(delta: float) -> void:
	_state_timer -= delta * speed_scale
	if _phase_index == -1:
		if _state_timer <= 0.0:
			emit_signal("calm_phase_ended")
			_start_next_phase()
		return

	if _shrinking:
		var progress: float = 1.0 - clamp(_state_timer / PHASE_SHRINK_TIME, 0.0, 1.0)
		current_center = _phase_start_center.lerp(_next_center, progress)
		current_radius = lerp(_phase_start_radius, _next_radius, progress)
		emit_signal("circle_updated", current_center, current_radius)
		if _state_timer <= 0.0:
			_shrinking = false
			_state_timer = PHASE_WAIT_TIME
			emit_signal("phase_advanced", _phase_index)
	else:
		if _state_timer <= 0.0:
			_start_next_phase()

	_apply_storm_damage(delta)

func _start_next_phase() -> void:
	_phase_index += 1
	_shrinking = true
	_state_timer = PHASE_SHRINK_TIME
	_phase_start_center = current_center
	_phase_start_radius = current_radius
	var max_offset: float = max(0.0, current_radius - _next_radius_guess())
	_next_center = current_center + Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0, max_offset)
	_next_radius = _next_radius_guess()

func _next_radius_guess() -> float:
	return max(15.0, current_radius * 0.65)

func _apply_storm_damage(delta: float) -> void:
	for p in _players:
		if not is_instance_valid(p) or not p.has_method("take_damage"):
			continue
		var pos2 := Vector2(p.global_position.x, p.global_position.z)
		var outside: bool = pos2.distance_to(current_center) > current_radius
		var should_damage := outside if not inverted else not outside
		if should_damage:
			p.take_damage(STORM_DAMAGE_PER_SEC * delta, null)
		elif inverted and outside:
			if p.has_method("heal"):
				p.heal(STORM_DAMAGE_PER_SEC * delta)

func current_phase() -> int:
	return max(_phase_index, 0)

func is_calm() -> bool:
	return _phase_index == -1

func time_remaining_in_state() -> float:
	return max(_state_timer, 0.0)
