class_name TrackerWeapon
extends WeaponBase
## Truesight Compass: finds the nearest enemy within lock_radius and fires a
## soft-homing projectile at them, so it "tracks people for you" instead of
## needing a precise aim.

func primary_use() -> void:
	if ammo_in_mag < 0:
		return
	var lock_radius: float = def.get("lock_radius", 80.0)
	var target := _find_nearest_enemy(lock_radius)
	var origin: Vector3 = owner_player.get_aim_origin()
	var dir: Vector3 = owner_player.get_aim_direction()
	HomingProjectile.spawn(owner_player.get_tree().current_scene, origin, dir, {
		"speed": 45.0,
		"homing_strength": def.get("homing_strength", 2.5),
		"damage": def.get("damage", 30.0),
		"shooter": owner_player,
		"target": target,
	})

func _find_nearest_enemy(radius: float) -> Node3D:
	var enemies := owner_player.get_tree().get_nodes_in_group("players")
	var best: Node3D = null
	var best_dist := radius
	for e in enemies:
		if e == owner_player:
			continue
		var d: float = owner_player.global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best
