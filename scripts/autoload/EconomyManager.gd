extends Node
## Handles the two currencies in the game and persists them to disk so
## progress survives between offline play sessions.
##
## - Battle Tokens: earned for free by playing (kills, wins, time-in-match).
##   Used to buy most cosmetic skins.
## - Gems: the premium, real-money currency. Purchases route through
##   ShopManager -> a (not-included) payment backend; revenue from Gem
##   purchases belongs to the game's operator, configured in
##   ShopManager.PAYOUT_ACCOUNT_NOTE.

signal tokens_changed(new_total: int)
signal gems_changed(new_total: int)

const TOKENS_PER_KILL := 25
const TOKENS_PER_WIN := 150
const TOKENS_PER_MINUTE := 5

const SAVE_PATH := "user://wallet.save"

var battle_tokens: int = 0
var gems: int = 0
var owned_skin_ids: Array[String] = ["default_recruit"]
var equipped_skin_id: String = "default_recruit"

func _ready() -> void:
	load_wallet()

func award_tokens(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	battle_tokens += amount
	emit_signal("tokens_changed", battle_tokens)
	save_wallet()

func spend_tokens(amount: int) -> bool:
	if amount > battle_tokens:
		return false
	battle_tokens -= amount
	emit_signal("tokens_changed", battle_tokens)
	save_wallet()
	return true

func add_gems(amount: int) -> void:
	gems += amount
	emit_signal("gems_changed", gems)
	save_wallet()

func spend_gems(amount: int) -> bool:
	if amount > gems:
		return false
	gems -= amount
	emit_signal("gems_changed", gems)
	save_wallet()
	return true

func owns_skin(skin_id: String) -> bool:
	return owned_skin_ids.has(skin_id)

func grant_skin(skin_id: String) -> void:
	if not owned_skin_ids.has(skin_id):
		owned_skin_ids.append(skin_id)
		save_wallet()

func equip_skin(skin_id: String) -> void:
	if owns_skin(skin_id):
		equipped_skin_id = skin_id
		save_wallet()

const RECRUIT_COLOR_PATH := "user://recruit_colors.save"

func get_recruit_colors() -> Dictionary:
	var palette: Dictionary = SkinDatabase.get_skin("default_recruit").palette.duplicate()
	if FileAccess.file_exists(RECRUIT_COLOR_PATH):
		var f := FileAccess.open(RECRUIT_COLOR_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			for k in ["head", "body", "clothes"]:
				if parsed.has(k):
					palette[k] = Color(parsed[k])
	return palette

func save_recruit_colors(colors: Dictionary) -> void:
	var f := FileAccess.open(RECRUIT_COLOR_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"head": colors.head.to_html(),
		"body": colors.body.to_html(),
		"clothes": colors.clothes.to_html(),
	}))
	f.close()

func save_wallet() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	var data := {
		"battle_tokens": battle_tokens,
		"gems": gems,
		"owned_skin_ids": owned_skin_ids,
		"equipped_skin_id": equipped_skin_id,
	}
	f.store_string(JSON.stringify(data))
	f.close()

func load_wallet() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	battle_tokens = parsed.get("battle_tokens", 0)
	gems = parsed.get("gems", 0)
	var owned = parsed.get("owned_skin_ids", ["default_recruit"])
	owned_skin_ids.assign(owned)
	equipped_skin_id = parsed.get("equipped_skin_id", "default_recruit")
