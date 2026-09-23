class_name HomingProjectile
extends Area3D
## A slow-curving projectile fired by the Truesight Compass. Steers toward
## `target` over its lifetime instead of snapping straight to it, so it can
## be dodged if the target breaks line of sight fast enough.

var velocity: Vector3 = Vector3.ZERO
var speed: float = 45.0
var homing_strength: float = 2.5
var damage: float = 30.0
var shooter: Node = null
var target: Node3D = null
var life: float = 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if is_instance_valid(target):
		var to_target: Vector3 = (target.global_position + Vector3.UP - global_position).normalized()
		velocity = velocity.lerp(to_target * speed, clamp(homing_strength * delta, 0.0, 1.0))
	global_position += velocity * delta
	if velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP)

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, shooter)
	queue_free()

## Builds a simple visible projectile (small emissive sphere) with a
## trigger collision shape, entirely from code so no .tscn asset is needed.
static func spawn(world: Node, from: Vector3, initial_dir: Vector3, cfg: Dictionary) -> HomingProjectile:
	var proj := HomingProjectile.new()
	proj.speed = cfg.get("speed", 45.0)
	proj.homing_strength = cfg.get("homing_strength", 2.5)
	proj.damage = cfg.get("damage", 30.0)
	proj.shooter = cfg.get("shooter")
	proj.target = cfg.get("target")
	proj.velocity = initial_dir.normalized() * proj.speed
	proj.collision_layer = 0
	proj.collision_mask = cfg.get("collision_mask", 1)

	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.8, 1.0)
	mat.albedo_color = Color(0.3, 0.8, 1.0)
	mesh_inst.material_override = mat
	proj.add_child(mesh_inst)

	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.2
	shape.shape = sphere_shape
	proj.add_child(shape)

	world.add_child(proj)
	proj.global_position = from
	return proj
