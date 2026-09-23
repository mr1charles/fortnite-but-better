class_name SuperchargeItem
extends WeaponBase
## Supercharge Core: grants temporary flight ("fly like Superman" pose --
## arm extended forward, body horizontal) at high speed. Goes on its own
## cooldown after the buff ends so it can't be chain-activated.

var active: bool = false
var _time_left: float = 0.0
var _cooldown: float = 0.0

func tick(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if active:
		_time_left -= delta
		if _time_left <= 0.0:
			_deactivate()

func try_use() -> bool:
	if active or _cooldown > 0.0:
		return false
	_activate()
	return true

func _activate() -> void:
	active = true
	_time_left = def.get("duration", 12.0)
	if owner_player.has_method("set_flight_enabled"):
		owner_player.set_flight_enabled(true, def.get("fly_speed", 22.0))
	if owner_player.has_method("set_animation_override"):
		owner_player.set_animation_override("fly_super")

func _deactivate() -> void:
	active = false
	_cooldown = def.get("cooldown", 45.0)
	if owner_player.has_method("set_flight_enabled"):
		owner_player.set_flight_enabled(false, 0.0)
	if owner_player.has_method("set_animation_override"):
		owner_player.set_animation_override("")
