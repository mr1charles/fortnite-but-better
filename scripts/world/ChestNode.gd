class_name ChestNode
extends Area3D
## A openable chest. Built procedurally (a tinted box) and drops 1-3 random
## weapon pickups around itself when a player walks up and interacts.

var opened: bool = false
var loot_rolls: int = 2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()

func _build_visual() -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.7, 0.7)
	mesh_inst.mesh = box
	mesh_inst.position.y = 0.35
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.65, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.4, 0.05)
	mat.emission_energy_multiplier = 0.4
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.4, 1.2, 1.2)
	shape.shape = box_shape
	shape.position.y = 0.35
	add_child(shape)

func _on_body_entered(body: Node) -> void:
	if opened or not body.is_in_group("players"):
		return
	open()

func open() -> void:
	if opened:
		return
	opened = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in loot_rolls:
		var id := WeaponDatabase.random_floor_loot_id(rng)
		var pickup := WeaponPickup.new()
		pickup.setup(id)
		get_parent().add_child(pickup)
		var offset := Vector3(rng.randf_range(-1.2, 1.2), 0.6, rng.randf_range(-1.2, 1.2))
		pickup.global_position = global_position + offset
	queue_free()
