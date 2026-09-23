class_name WeaponPickup
extends Area3D
## A weapon/item lying on the ground. Built procedurally (no mesh asset
## needed): a colored box sized/tinted by rarity, spinning slowly.

var weapon_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()

func setup(id: String) -> void:
	weapon_id = id

func _process(delta: float) -> void:
	rotate_y(delta * 1.2)

func _build_visual() -> void:
	var def := WeaponDatabase.get_weapon(weapon_id)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 0.35, 0.9)
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _rarity_tint(def.get("rarity", 0))
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.6
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(0.6, 0.6, 1.1)
	shape.shape = box_shape
	add_child(shape)

func _rarity_tint(rarity: int) -> Color:
	match rarity:
		WeaponDatabase.Rarity.COMMON: return Color(0.75, 0.75, 0.75)
		WeaponDatabase.Rarity.UNCOMMON: return Color(0.4, 0.85, 0.4)
		WeaponDatabase.Rarity.RARE: return Color(0.3, 0.55, 1.0)
		WeaponDatabase.Rarity.EPIC: return Color(0.7, 0.3, 0.95)
		WeaponDatabase.Rarity.LEGENDARY: return Color(1.0, 0.65, 0.15)
		WeaponDatabase.Rarity.MYTHIC: return Color(1.0, 0.9, 0.3)
		_: return Color.WHITE

func _on_body_entered(body: Node) -> void:
	if body.has_method("pickup_weapon"):
		body.pickup_weapon(weapon_id)
		queue_free()
