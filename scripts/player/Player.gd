class_name Player
extends CharacterBody3D
## The offline player character. Handles movement, camera, health/shields,
## the weapon-slot inventory (primary / secondary / back / consumable), a
## minimal build system, and the hooks every WeaponBase subclass and Tech
## rule effect drives (flight, speed multiplier, animation overrides, ...).

signal took_damage(amount: float, attacker: Node3D)
signal died(killer: Node3D)
signal weapon_evolved(new_name: String)

const WALK_SPEED := 6.0
const SPRINT_SPEED := 9.5
const JUMP_VELOCITY := 8.5
const MOUSE_SENSITIVITY := 0.0025

@export var max_health: float = 100.0
@export var max_shield: float = 100.0
@export var player_name: String = "Player"

var health: float
var shield: float
var alive: bool = true

var speed_multiplier: float = 1.0
var damage_taken_multiplier: float = 1.0
var damage_dealt_multiplier: float = 1.0
var jump_enabled: bool = true
var build_enabled: bool = true
var flight_enabled: bool = false
var flight_speed: float = 20.0
var can_double_jump: bool = false
var jumps_used: int = 0
var extra_jumps: int = 0
var afterimages_enabled: bool = false
var _animation_override: String = ""

var slots: Dictionary = {} # Slot enum -> WeaponBase instance
var active_slot: int = WeaponDatabase.Slot.PRIMARY

var customization: PlayerCustomization
var camera: Camera3D
var spring_arm: SpringArm3D
var third_person: bool = true

var is_bot: bool = false
var bot_input_dir: Vector2 = Vector2.ZERO
var bot_wants_jump: bool = false
var bot_aim_direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	add_to_group("players")
	health = max_health
	shield = max_shield
	_build_visuals()
	_build_camera()
	var equipped := EconomyManager.equipped_skin_id
	var overrides := EconomyManager.get_recruit_colors() if equipped == "default_recruit" else {}
	customization.set_skin(equipped, overrides)

func _build_visuals() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)

	customization = PlayerCustomization.new()
	customization.name = "Customization"
	add_child(customization)

func _build_camera() -> void:
	spring_arm = SpringArm3D.new()
	spring_arm.position = Vector3(0, 1.6, 0)
	spring_arm.spring_length = 4.0
	add_child(spring_arm)
	camera = Camera3D.new()
	spring_arm.add_child(camera)
	camera.current = not is_bot

func _unhandled_input(event: InputEvent) -> void:
	if is_bot:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	if event.is_action_pressed("toggle_camera"):
		third_person = not third_person
		spring_arm.spring_length = 4.0 if third_person else 0.05
	if event.is_action_pressed("fire_primary"):
		use_active_weapon()
	if event.is_action_pressed("use_consumable"):
		use_consumable()
	if event.is_action_pressed("reload") and slots.has(active_slot):
		slots[active_slot].start_reload()
	if event.is_action_pressed("build_wall"):
		place_build_piece("wall")
	if event.is_action_pressed("build_floor"):
		place_build_piece("floor")

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if flight_enabled:
		_process_flight(delta)
	else:
		_process_ground_movement(delta)
	move_and_slide()
	for slot in slots:
		slots[slot].tick(delta)

func _process_ground_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 20.0) * delta
	else:
		jumps_used = 0
		if velocity.y < 0:
			velocity.y = 0

	var jump_pressed: bool = bot_wants_jump if is_bot else Input.is_action_just_pressed("jump")
	if jump_pressed:
		_try_jump()
	bot_wants_jump = false

	var input_dir: Vector2 = bot_input_dir if is_bot else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var base_speed := SPRINT_SPEED if (not is_bot and Input.is_action_pressed("sprint")) else WALK_SPEED
	var target_speed := base_speed * speed_multiplier
	if direction != Vector3.ZERO:
		velocity.x = direction.x * target_speed
		velocity.z = direction.z * target_speed
	else:
		velocity.x = move_toward(velocity.x, 0, target_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, target_speed * 8.0 * delta)

func _process_flight(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var vertical := 0.0
	if Input.is_action_pressed("jump"):
		vertical = 1.0
	elif Input.is_action_pressed("crouch"):
		vertical = -1.0
	var forward := (transform.basis * Vector3(input_dir.x, vertical, input_dir.y)).normalized()
	velocity = forward * flight_speed

func _try_jump() -> void:
	if not jump_enabled:
		return
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumps_used = 1
	elif can_double_jump and jumps_used <= extra_jumps:
		velocity.y = JUMP_VELOCITY * 0.9
		jumps_used += 1

# ---------------------------------------------------------------------
# Combat
# ---------------------------------------------------------------------

func take_damage(amount: float, attacker: Node3D = null) -> void:
	if not alive:
		return
	var final_amount := amount * damage_taken_multiplier
	var from_shield := min(shield, final_amount)
	shield -= from_shield
	final_amount -= from_shield
	health -= final_amount
	emit_signal("took_damage", amount, attacker)
	if health <= 0:
		_die(attacker)

func heal(amount: float) -> void:
	health = min(max_health, health + amount)

func apply_status(status_name: String, params: Dictionary) -> void:
	match status_name:
		"bleed":
			_apply_bleed(params.get("dps", 2.0), params.get("duration", 3.0))
		"armor_shred":
			shield = max(0.0, shield - shield * params.get("amount", 0.25))
		_:
			pass

func _apply_bleed(dps: float, duration: float) -> void:
	var ticks := int(duration)
	for i in ticks:
		await get_tree().create_timer(1.0).timeout
		if alive:
			take_damage(dps, null)

func apply_knockback(impulse: Vector3) -> void:
	velocity += impulse

func _die(killer: Node3D) -> void:
	alive = false
	emit_signal("died", killer)
	var killer_name: String = killer.player_name if (killer and killer is Player) else "the storm"
	GameManager.report_elimination(player_name, killer_name)

# ---------------------------------------------------------------------
# Weapons / inventory
# ---------------------------------------------------------------------

func pickup_weapon(weapon_id: String) -> void:
	var def := WeaponDatabase.get_weapon(weapon_id)
	if def.is_empty():
		return
	var script := load(def.script_path)
	var instance: WeaponBase = script.new()
	instance.setup(def, self)
	var slot: int = def.get("slot", WeaponDatabase.Slot.PRIMARY)
	if slots.has(slot):
		slots[slot].queue_free()
	slots[slot] = instance
	add_child(instance)
	if slot == WeaponDatabase.Slot.PRIMARY:
		active_slot = slot

func use_active_weapon() -> void:
	if slots.has(active_slot):
		slots[active_slot].try_use()

func use_consumable() -> void:
	if slots.has(WeaponDatabase.Slot.CONSUMABLE):
		slots[WeaponDatabase.Slot.CONSUMABLE].try_use()

func notify_weapon_evolved(new_name: String) -> void:
	emit_signal("weapon_evolved", new_name)

func get_aim_origin() -> Vector3:
	return global_position + Vector3(0, 1.6, 0) if is_bot else camera.global_position

func get_aim_direction() -> Vector3:
	return bot_aim_direction if is_bot else -camera.global_transform.basis.z

# ---------------------------------------------------------------------
# Ability / Tech-rule hooks
# ---------------------------------------------------------------------

func set_flight_enabled(enabled: bool, speed: float) -> void:
	flight_enabled = enabled
	flight_speed = speed
	if not enabled:
		velocity = Vector3.ZERO

func set_speed_multiplier(mult: float) -> void:
	speed_multiplier = mult

func set_afterimages_enabled(enabled: bool) -> void:
	afterimages_enabled = enabled

func set_animation_override(state_name: String) -> void:
	_animation_override = state_name

func set_jump_enabled(enabled: bool) -> void:
	jump_enabled = enabled

func set_build_enabled(enabled: bool) -> void:
	build_enabled = enabled

func grant_double_jump(extra: int = 1) -> void:
	can_double_jump = true
	extra_jumps = extra

func set_gravity_scale(_scale: float) -> void:
	pass # gravity is applied globally by StormManager/TechBattleMode via ProjectSettings

func set_damage_taken_multiplier(mult: float) -> void:
	damage_taken_multiplier = mult

func set_damage_dealt_multiplier(mult: float) -> void:
	damage_dealt_multiplier = mult

# ---------------------------------------------------------------------
# Minimal build system (structures a Tech rule can disable via no_build)
# ---------------------------------------------------------------------

func place_build_piece(kind: String) -> void:
	if not build_enabled:
		return
	var piece := StaticBody3D.new()
	piece.add_to_group("destructible")
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 0.2) if kind == "wall" else Vector3(2.0, 0.2, 2.0)
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.35)
	mesh_inst.material_override = mat
	piece.add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box.size
	shape.shape = box_shape
	piece.add_child(shape)
	get_tree().current_scene.add_child(piece)
	var forward := -global_transform.basis.z
	var place_pos := global_position + Vector3(0, 1.0, 0) + forward * 2.5
	if kind == "wall":
		piece.global_position = place_pos
		piece.look_at(piece.global_position + forward, Vector3.UP)
	else:
		place_pos.y = global_position.y
		piece.global_position = place_pos
