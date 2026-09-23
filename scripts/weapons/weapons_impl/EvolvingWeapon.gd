class_name EvolvingWeapon
extends WeaponBase
## Momentum Blade: a melee weapon that permanently upgrades itself the more
## damage it lands, moving through `def.tiers`. Each tier raises base
## damage and unlocks a passive bonus (bleed / armor_shred / lifesteal).

var lifetime_damage: float = 0.0
var current_tier: int = 0

func setup(weapon_def: Dictionary, player: Node3D) -> void:
	super.setup(weapon_def, player)
	current_tier = 0

func primary_use() -> void:
	var tier: Dictionary = def.tiers[current_tier]
	var damage: float = tier.damage
	var result := hitscan_from_player(damage, def.get("range", 2.5))
	if result and result.has("collider") and result.collider.has_method("take_damage"):
		_apply_bonus(tier.bonus, result.collider, damage)
		_register_damage(damage)

func _apply_bonus(bonus: String, target: Node, damage: float) -> void:
	match bonus:
		"bleed":
			if target.has_method("apply_status"):
				target.apply_status("bleed", {"dps": damage * 0.1, "duration": 3.0})
		"armor_shred":
			if target.has_method("apply_status"):
				target.apply_status("armor_shred", {"amount": 0.25, "duration": 5.0})
		"lifesteal":
			if owner_player.has_method("heal"):
				owner_player.heal(damage * 0.3)
		_:
			pass

func _register_damage(amount: float) -> void:
	lifetime_damage += amount
	var next_tier := current_tier + 1
	if next_tier < def.tiers.size() and lifetime_damage >= def.tiers[next_tier].damage_needed:
		current_tier = next_tier
		if owner_player.has_method("notify_weapon_evolved"):
			owner_player.notify_weapon_evolved(def.tiers[current_tier].name)

func get_current_tier_name() -> String:
	return def.tiers[current_tier].name
