class_name GameModeBase
extends Node
## Shared wiring both game modes need: spawning the world, players, storm,
## and loot, then starting the match clock through GameManager.

var world: WorldGenerator
var loot_spawner: LootSpawner
var storm: StormManager
var players: Array[Node3D] = []

func setup(world_node: WorldGenerator, loot_node: LootSpawner, storm_node: StormManager, player_list: Array[Node3D]) -> void:
	world = world_node
	loot_spawner = loot_node
	storm = storm_node
	players = player_list
	storm.register_players(players)

func start() -> void:
	loot_spawner.spawn_initial_loot()
	var names: Array[String] = []
	for p in players:
		names.append(p.player_name)
	GameManager.start_match(mode_id(), names)

func mode_id() -> int:
	return GameManager.GameMode.BATTLE_ROYALE
