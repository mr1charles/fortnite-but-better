class_name WorldGenerator
extends Node3D
## Builds the one big island map procedurally, entirely from primitives, so
## the project needs zero imported art/terrain assets to be playable.
## The island is split into six biomes, each with a couple of named POIs
## (Points of Interest) built out of simple block "buildings" that hold
## extra loot density.

const ISLAND_RADIUS := 380.0

var biomes: Array[Dictionary] = [
	{"name": "Verdant Fields", "color": Color(0.30, 0.55, 0.25), "center": Vector2(-180, -140), "radius": 150.0, "loot_mult": 1.0},
	{"name": "Scorched Dunes", "color": Color(0.78, 0.65, 0.35), "center": Vector2(160, -170), "radius": 150.0, "loot_mult": 0.9},
	{"name": "Frostpeak Ridge", "color": Color(0.85, 0.90, 0.95), "center": Vector2(-170, 160), "radius": 150.0, "loot_mult": 1.0},
	{"name": "Mire Marsh", "color": Color(0.25, 0.35, 0.22), "center": Vector2(170, 160), "radius": 150.0, "loot_mult": 1.1},
	{"name": "Ashen Wastes", "color": Color(0.35, 0.30, 0.30), "center": Vector2(0, -240), "radius": 120.0, "loot_mult": 1.3},
	{"name": "Neon Sprawl", "color": Color(0.28, 0.22, 0.42), "center": Vector2(0, 0), "radius": 130.0, "loot_mult": 1.4},
]

var pois: Array[Dictionary] = [
	{"name": "Harvest Hollow", "biome": "Verdant Fields", "pos": Vector2(-200, -120), "buildings": 5},
	{"name": "Windmill Row", "biome": "Verdant Fields", "pos": Vector2(-140, -180), "buildings": 3},
	{"name": "Dustbowl Outpost", "biome": "Scorched Dunes", "pos": Vector2(180, -150), "buildings": 4},
	{"name": "Cracked Oasis", "biome": "Scorched Dunes", "pos": Vector2(120, -210), "buildings": 2},
	{"name": "Icefall Station", "biome": "Frostpeak Ridge", "pos": Vector2(-190, 140), "buildings": 4},
	{"name": "Glacier Camp", "biome": "Frostpeak Ridge", "pos": Vector2(-130, 200), "buildings": 3},
	{"name": "Bogwater Village", "biome": "Mire Marsh", "pos": Vector2(190, 140), "buildings": 5},
	{"name": "Sunken Pier", "biome": "Mire Marsh", "pos": Vector2(140, 200), "buildings": 2},
	{"name": "Cinder Works", "biome": "Ashen Wastes", "pos": Vector2(0, -230), "buildings": 6},
	{"name": "Neon Central", "biome": "Neon Sprawl", "pos": Vector2(0, 10), "buildings": 8},
]

var loot_spawn_points: Array[Vector3] = []
var chest_spawn_points: Array[Vector3] = []

func _ready() -> void:
	_build_ground()
	_build_biome_tint_overlays()
	_build_pois()
	_scatter_loot_points()

func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	add_child(body)
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ISLAND_RADIUS * 2.2, ISLAND_RADIUS * 2.2)
	plane.subdivide_width = 40
	plane.subdivide_depth = 40
	mesh_inst.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.45, 0.3)
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ISLAND_RADIUS * 2.2, 1.0, ISLAND_RADIUS * 2.2)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 0)
	body.add_child(shape)

func _build_biome_tint_overlays() -> void:
	# Thin colored disks laid just above the ground per biome so the map
	# visibly reads as distinct regions without needing a splat-mapped
	# terrain shader or any imported textures.
	for biome in biomes:
		var disk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = biome.radius
		cyl.bottom_radius = biome.radius
		cyl.height = 0.05
		disk.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.albedo_color = biome.color
		disk.material_override = mat
		disk.position = Vector3(biome.center.x, 0.03, biome.center.y)
		add_child(disk)

func _build_pois() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for poi in pois:
		var poi_root := Node3D.new()
		poi_root.name = poi.name.replace(" ", "_")
		poi_root.position = Vector3(poi.pos.x, 0, poi.pos.y)
		add_child(poi_root)
		for i in poi.buildings:
			var b := _make_building(rng)
			var offset := Vector2(rng.randf_range(-18, 18), rng.randf_range(-18, 18))
			b.position = Vector3(offset.x, 0, offset.y)
			poi_root.add_child(b)
			chest_spawn_points.append(poi_root.global_position + b.position + Vector3(0, 1.0, 0))

func _make_building(rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	var w := rng.randf_range(4.0, 9.0)
	var h := rng.randf_range(3.0, 8.0)
	var d := rng.randf_range(4.0, 9.0)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w, h, d)
	mesh_inst.mesh = box
	mesh_inst.position.y = h * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(rng.randf_range(0.4, 0.7), rng.randf_range(0.35, 0.6), rng.randf_range(0.3, 0.55))
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box.size
	shape.position.y = h * 0.5
	shape.shape = box_shape
	body.add_child(shape)
	return body

func _scatter_loot_points() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for i in 160:
		var angle := rng.randf_range(0, TAU)
		var dist := sqrt(rng.randf()) * ISLAND_RADIUS * 0.95
		var pos := Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)
		loot_spawn_points.append(pos)

func biome_at(world_pos: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_dist := INF
	var p := Vector2(world_pos.x, world_pos.z)
	for biome in biomes:
		var d: float = p.distance_to(biome.center)
		if d < biome.radius and d < best_dist:
			best_dist = d
			best = biome
	return best
