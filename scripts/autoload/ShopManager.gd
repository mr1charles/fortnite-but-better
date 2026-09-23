extends Node
## Item Shop logic: buying skins with Battle Tokens or Gems, and buying Gem
## packs with real money. Autoloaded as "ShopManager".
##
## IMPORTANT: this project is fully offline and ships with no payment
## processor wired up. `purchase_gem_pack()` below is a local stand-in that
## just grants Gems directly so the offline game is playable end-to-end.
## To take real money you need a real backend (e.g. Stripe) that verifies a
## payment server-side before calling add_gems() -- never trust a client to
## grant paid currency to itself in a real deployment. All Gem-pack revenue
## is configured to route to the game's operator once that backend exists;
## see PAYOUT_OWNER_NOTE.

signal purchase_succeeded(item_id: String)
signal purchase_failed(item_id: String, reason: String)

const PAYOUT_OWNER_NOTE := "All real-money Gem purchases are configured to pay out to the game's owner/operator account once a payment backend (e.g. Stripe) is connected."

# Real-money Gem packs. "price_usd" is illustrative only until a payment
# backend is connected.
var gem_packs: Array[Dictionary] = [
	{"id": "gems_small", "gems": 500, "price_usd": 4.99},
	{"id": "gems_medium", "gems": 1200, "price_usd": 9.99},
	{"id": "gems_large", "gems": 3000, "price_usd": 19.99},
	{"id": "gems_mega", "gems": 8000, "price_usd": 49.99},
]

func daily_rotation() -> Array:
	# Deterministic-per-day "rotation" so the shop still feels alive offline.
	var day := int(Time.get_unix_time_from_system() / 86400.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = day
	var pool: Array = SkinDatabase.all_skins().filter(func(s): return s.id != "default_recruit")
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, min(6, pool.size()))

func purchase_skin(skin_id: String) -> bool:
	var skin := SkinDatabase.get_skin(skin_id)
	if skin.id != skin_id:
		emit_signal("purchase_failed", skin_id, "unknown_item")
		return false
	if EconomyManager.owns_skin(skin_id):
		emit_signal("purchase_failed", skin_id, "already_owned")
		return false
	var ok := false
	if skin.currency == SkinDatabase.Currency.TOKENS:
		ok = EconomyManager.spend_tokens(skin.price)
	else:
		ok = EconomyManager.spend_gems(skin.price)
	if ok:
		EconomyManager.grant_skin(skin_id)
		emit_signal("purchase_succeeded", skin_id)
	else:
		emit_signal("purchase_failed", skin_id, "insufficient_funds")
	return ok

func purchase_gem_pack(pack_id: String) -> bool:
	for pack in gem_packs:
		if pack.id == pack_id:
			# Offline stand-in only -- see class doc comment above.
			EconomyManager.add_gems(pack.gems)
			emit_signal("purchase_succeeded", pack_id)
			return true
	emit_signal("purchase_failed", pack_id, "unknown_pack")
	return false
