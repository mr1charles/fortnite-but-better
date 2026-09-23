class_name StandardWeapon
extends WeaponBase
## Ordinary hitscan guns: assault rifle, SMG, shotgun, sniper. Behavior
## differences come entirely from the `def` stats (pellets/spread for
## shotguns, range/damage for snipers, etc.) so no per-gun script is needed.

func primary_use() -> void:
	var damage: float = def.get("damage", 10.0)
	var max_range: float = def.get("range", 40.0)
	var pellets: int = def.get("pellets", 1)
	var spread: float = def.get("spread_deg", 0.0)
	for i in pellets:
		hitscan_from_player(damage, max_range, spread)
