class_name Main
extends Node3D
## Root of an actual match. Spawns the world, the local player (plus a
## handful of simple bots so Battle Royale/Tech Battle aren't a 1-player
## simulation), wires up the chosen GameModeBase, and hosts the HUD.

static var pending_mode: int = GameManager.GameMode.BATTLE_ROYALE

const BOT_COUNT := 11
const BOT_NAMES := ["Ash", "Blaze", "Cinder", "Dune", "Echo", "Frost", "Grit", "Halo", "Ivy", "Jax", "Kite"]

var world: WorldGenerator
var loot_spawner: LootSpawner
var storm: StormManager
var mode: GameModeBase
var local_player: Player
var all_players: Array[Node3D] = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_environment()
	_build_world()
	_spawn_players()
	_start_mode()
	_attach_hud()

func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = load("res://default_env.tres")
	add_child(env)

func _build_world() -> void:
	world = WorldGenerator.new()
	world.name = "World"
	add_child(world)
	loot_spawner = LootSpawner.new()
	loot_spawner.name = "LootSpawner"
	loot_spawner.setup(world)
	add_child(loot_spawner)
	storm = StormManager.new()
	storm.name = "Storm"
	add_child(storm)

func _spawn_players() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	local_player = _spawn_one(GameManager.local_player_name, rng, false)
	all_players.append(local_player)
	for i in BOT_COUNT:
		var bot := _spawn_one(BOT_NAMES[i % BOT_NAMES.size()] + "_%d" % i, rng, true)
		all_players.append(bot)

func _spawn_one(name: String, rng: RandomNumberGenerator, as_bot: bool) -> Player:
	var p := preload("res://scenes/Player.tscn").instantiate() as Player
	p.player_name = name
	p.is_bot = as_bot
	add_child(p)
	var angle := rng.randf_range(0, TAU)
	var dist := rng.randf_range(0, WorldGenerator.ISLAND_RADIUS * 0.85)
	p.global_position = Vector3(cos(angle) * dist, 2.0, sin(angle) * dist)
	if as_bot:
		var ai := BotAI.new()
		ai.player = p
		p.add_child(ai)
	return p

func _start_mode() -> void:
	if pending_mode == GameManager.GameMode.TECH_BATTLE:
		mode = TechBattleMode.new()
	else:
		mode = BattleRoyaleMode.new()
	add_child(mode)
	mode.setup(world, loot_spawner, storm, all_players)
	mode.start()

func _attach_hud() -> void:
	var hud := preload("res://scenes/ui/HUD.tscn").instantiate()
	hud.setup(local_player, storm, mode)
	add_child(hud)
