extends Node
## Global match/session state. Autoloaded as "GameManager".
##
## Tracks the active game mode, players alive, elapsed time, and hands out
## Battle Token rewards for kills / wins / playtime when a match ends.

signal match_started(mode_id: String)
signal match_ended(result: Dictionary)
signal player_eliminated(player_name: String, killer_name: String)

enum GameMode { BATTLE_ROYALE, TECH_BATTLE }

const CALM_PHASE_SECONDS := 45.0

var current_mode: int = GameMode.BATTLE_ROYALE
var match_active: bool = false
var match_time_elapsed: float = 0.0
var local_player_name: String = "Player"

var local_stats := {
	"kills": 0,
	"damage_dealt": 0.0,
	"wins": 0,
	"matches_played": 0,
}

var _players_alive: Array[String] = []

func start_match(mode: int, player_roster: Array[String]) -> void:
	current_mode = mode
	match_active = true
	match_time_elapsed = 0.0
	_players_alive = player_roster.duplicate()
	local_stats.matches_played += 1
	emit_signal("match_started", GameMode.keys()[mode])

func _process(delta: float) -> void:
	if match_active:
		match_time_elapsed += delta

func report_elimination(victim: String, killer: String) -> void:
	_players_alive.erase(victim)
	emit_signal("player_eliminated", victim, killer)
	if killer == local_player_name and victim != local_player_name:
		local_stats.kills += 1
		EconomyManager.award_tokens(EconomyManager.TOKENS_PER_KILL, "kill")
	if _players_alive.size() <= 1:
		_end_match()

func _end_match() -> void:
	if not match_active:
		return
	match_active = false
	var winner := "" if _players_alive.is_empty() else _players_alive[0]
	var did_win := winner == local_player_name
	if did_win:
		local_stats.wins += 1
		EconomyManager.award_tokens(EconomyManager.TOKENS_PER_WIN, "win")
	var minutes_played := match_time_elapsed / 60.0
	var playtime_tokens := int(floor(minutes_played * EconomyManager.TOKENS_PER_MINUTE))
	if playtime_tokens > 0:
		EconomyManager.award_tokens(playtime_tokens, "playtime")
	emit_signal("match_ended", {
		"winner": winner,
		"did_win": did_win,
		"duration": match_time_elapsed,
		"kills": local_stats.kills,
	})

func players_alive_count() -> int:
	return _players_alive.size()
