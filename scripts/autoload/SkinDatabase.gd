extends Node
## Catalog of every skin in the game, autoloaded as "SkinDatabase".
##
## "default_recruit" is free for everyone and is the only skin whose colors
## the player can freely recustomize (head / body / clothing color pickers).
## Every other skin is a fixed, purchasable cosmetic priced in Battle Tokens
## and/or Gems (the paid currency). Prices below are the ones ShopManager
## reads for the item shop.

enum Currency { TOKENS, GEMS }
enum Rarity { FREE, COMMON, RARE, EPIC, LEGENDARY }

# Each entry:
# id, name, rarity, price {currency, amount}, customizable (bool),
# palette (default colors used if customizable), tags (cosmetic flavor only)
var skins: Dictionary = {}

func _ready() -> void:
	_register(
		"default_recruit", "Recruit", Rarity.FREE,
		Currency.TOKENS, 0, true,
		{"head": Color(0.85, 0.7, 0.55), "body": Color(0.2, 0.35, 0.55), "clothes": Color(0.15, 0.15, 0.18)}
	)
	_register("ember_walker", "Ember Walker", Rarity.COMMON, Currency.TOKENS, 800, false,
		{"head": Color(0.9, 0.5, 0.3), "body": Color(0.6, 0.15, 0.1), "clothes": Color(0.2, 0.05, 0.05)})
	_register("frost_sentinel", "Frost Sentinel", Rarity.RARE, Currency.TOKENS, 1500, false,
		{"head": Color(0.8, 0.9, 1.0), "body": Color(0.3, 0.55, 0.8), "clothes": Color(0.9, 0.95, 1.0)})
	_register("void_jester", "Void Jester", Rarity.EPIC, Currency.TOKENS, 2800, false,
		{"head": Color(0.5, 0.1, 0.6), "body": Color(0.1, 0.02, 0.15), "clothes": Color(0.7, 0.2, 0.8)})
	_register("solar_paragon", "Solar Paragon", Rarity.LEGENDARY, Currency.GEMS, 1200, false,
		{"head": Color(1.0, 0.85, 0.3), "body": Color(1.0, 0.6, 0.1), "clothes": Color(1.0, 0.95, 0.7)})
	_register("crimson_reaver", "Crimson Reaver", Rarity.EPIC, Currency.GEMS, 900, false,
		{"head": Color(0.6, 0.05, 0.05), "body": Color(0.15, 0.02, 0.02), "clothes": Color(0.4, 0.0, 0.0)})
	_register("hollow_knight_errant", "Hollow Errant", Rarity.RARE, Currency.TOKENS, 1600, false,
		{"head": Color(0.2, 0.2, 0.22), "body": Color(0.35, 0.35, 0.4), "clothes": Color(0.1, 0.1, 0.12)})
	_register("gilded_kraken", "Gilded Kraken", Rarity.LEGENDARY, Currency.GEMS, 1500, false,
		{"head": Color(0.1, 0.4, 0.35), "body": Color(0.85, 0.7, 0.2), "clothes": Color(0.05, 0.25, 0.2)})

func _register(id: String, display_name: String, rarity: int, currency: int, price: int,
		customizable: bool, palette: Dictionary) -> void:
	skins[id] = {
		"id": id,
		"name": display_name,
		"rarity": rarity,
		"currency": currency,
		"price": price,
		"customizable": customizable,
		"palette": palette,
	}

func get_skin(id: String) -> Dictionary:
	return skins.get(id, skins["default_recruit"])

func all_skins() -> Array:
	return skins.values()

func rarity_name(rarity: int) -> String:
	return Rarity.keys()[rarity].capitalize()

func rarity_color(rarity: int) -> Color:
	match rarity:
		Rarity.FREE: return Color(0.7, 0.7, 0.7)
		Rarity.COMMON: return Color(0.65, 0.85, 0.65)
		Rarity.RARE: return Color(0.35, 0.6, 1.0)
		Rarity.EPIC: return Color(0.7, 0.3, 0.95)
		Rarity.LEGENDARY: return Color(1.0, 0.75, 0.2)
		_: return Color.WHITE
