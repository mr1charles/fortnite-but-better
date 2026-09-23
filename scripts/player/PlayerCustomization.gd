class_name PlayerCustomization
extends Node3D
## Builds the player's visible body entirely from primitives so the game
## needs zero external art to run. The free "Recruit" skin exposes three
## colors (head / body / clothes) the player can repaint in the Skin
## Customizer; every purchased skin instead uses its own fixed palette
## from SkinDatabase.

var head_mesh: MeshInstance3D
var torso_mesh: MeshInstance3D
var clothes_mesh: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D

var skin_id: String = "default_recruit"
var custom_colors: Dictionary = {}

func _ready() -> void:
	if head_mesh == null:
		_build_body()
	refresh()

func _build_body() -> void:
	head_mesh = _make_part(SphereMesh.new(), Vector3(0, 1.65, 0))
	(head_mesh.mesh as SphereMesh).radius = 0.22
	(head_mesh.mesh as SphereMesh).height = 0.44
	head_mesh.name = "Head"

	torso_mesh = _make_part(CapsuleMesh.new(), Vector3(0, 1.15, 0))
	(torso_mesh.mesh as CapsuleMesh).radius = 0.28
	(torso_mesh.mesh as CapsuleMesh).height = 0.9
	torso_mesh.name = "Torso"

	clothes_mesh = _make_part(BoxMesh.new(), Vector3(0, 1.15, 0))
	(clothes_mesh.mesh as BoxMesh).size = Vector3(0.6, 0.5, 0.35)
	clothes_mesh.name = "Clothes"

	left_arm = _make_part(CapsuleMesh.new(), Vector3(-0.42, 1.15, 0))
	(left_arm.mesh as CapsuleMesh).radius = 0.09
	(left_arm.mesh as CapsuleMesh).height = 0.7
	left_arm.name = "LeftArm"

	right_arm = _make_part(CapsuleMesh.new(), Vector3(0.42, 1.15, 0))
	(right_arm.mesh as CapsuleMesh).radius = 0.09
	(right_arm.mesh as CapsuleMesh).height = 0.7
	right_arm.name = "RightArm"

func _make_part(mesh: Mesh, pos: Vector3) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	var mat := StandardMaterial3D.new()
	inst.material_override = mat
	add_child(inst)
	return inst

func set_skin(id: String, colors_override: Dictionary = {}) -> void:
	skin_id = id
	custom_colors = colors_override
	refresh()

func refresh() -> void:
	var def := SkinDatabase.get_skin(skin_id)
	var palette: Dictionary = def.get("palette", {})
	if def.get("customizable", false) and not custom_colors.is_empty():
		palette = custom_colors
	_paint(head_mesh, palette.get("head", Color.WHEAT))
	_paint(torso_mesh, palette.get("body", Color.STEEL_BLUE))
	_paint(clothes_mesh, palette.get("clothes", Color.DIM_GRAY))
	_paint(left_arm, palette.get("body", Color.STEEL_BLUE))
	_paint(right_arm, palette.get("body", Color.STEEL_BLUE))

func _paint(part: MeshInstance3D, color: Color) -> void:
	if part == null:
		return
	var mat := part.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
