class_name SmashGauntlets
extends WeaponBase
## Rampart Gauntlets: short-range ground-pound melee that damages and
## knocks back anything in front of the player and destroys any
## Destructible structure piece it touches ("break things like Hulk").

func primary_use() -> void:
	if owner_player.has_method("set_animation_override"):
		owner_player.set_animation_override("smash_ground")
	var range: float = def.get("range", 3.0)
	var damage: float = def.get("damage", 80.0)
	var knockback: float = def.get("knockback", 14.0)
	var space_state := owner_player.get_world_3d().direct_space_state
	var origin: Vector3 = owner_player.get_aim_origin()
	var dir: Vector3 = owner_player.get_aim_direction()
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = range
	query.shape = shape
	query.transform = Transform3D(Basis(), origin + dir * (range * 0.5))
	query.exclude = [owner_player.get_rid()]
	var hits := space_state.intersect_shape(query, 8)
	for hit in hits:
		var collider = hit.collider
		if collider.has_method("take_damage"):
			collider.take_damage(damage, owner_player)
			if collider.has_method("apply_knockback"):
				var away: Vector3 = (collider.global_position - owner_player.global_position).normalized()
				collider.apply_knockback(away * knockback)
		elif collider.is_in_group("destructible"):
			collider.queue_free()
