class_name SpeedBoost
extends WeaponBase
## Momentum Boots: temporary super-speed ("run like the Flash/Sonic" pose,
## motion-blur afterimages) with its own post-use cooldown.

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
	_time_left = def.get("duration", 8.0)
	if owner_player.has_method("set_speed_multiplier"):
		owner_player.set_speed_multiplier(def.get("speed_multiplier", 3.2))
	if owner_player.has_method("set_animation_override"):
		owner_player.set_animation_override("sprint_blur")
	if owner_player.has_method("set_afterimages_enabled") and def.get("leaves_afterimages", false):
		owner_player.set_afterimages_enabled(true)

func _deactivate() -> void:
	active = false
	_cooldown = def.get("cooldown", 30.0)
	if owner_player.has_method("set_speed_multiplier"):
		owner_player.set_speed_multiplier(1.0)
	if owner_player.has_method("set_animation_override"):
		owner_player.set_animation_override("")
	if owner_player.has_method("set_afterimages_enabled"):
		owner_player.set_afterimages_enabled(false)
