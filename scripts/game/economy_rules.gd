extends RefCounted

const RunRulesScript = preload("res://scripts/game/run_rules.gd")

const MAX_ROUNDS := RunRulesScript.MAX_ROUNDS
const ROUND_CLEAR_ORE_REWARDS := {
	1: 6,
	2: 6,
}


static func fresh_wallet(currency_ids: Array) -> Dictionary:
	var wallet := {}
	for raw_id in currency_ids:
		var currency_id := str(raw_id)
		if currency_id.is_empty() or wallet.has(currency_id):
			continue
		wallet[currency_id] = {"balance": 0, "acquired": 0, "spent": 0}
	return wallet


static func validate_typed_cost(cost: Dictionary, currency_ids: Array) -> Dictionary:
	if not cost.has("currency_id") or not cost.has("amount"):
		return {"ok": false, "error": "invalid_cost_shape", "cost": {}}
	var currency_id := str(cost.get("currency_id", ""))
	if not currency_ids.has(currency_id):
		return {"ok": false, "error": "unknown_currency", "cost": {}}
	var raw_amount: Variant = cost.get("amount", null)
	if typeof(raw_amount) != TYPE_INT:
		return {"ok": false, "error": "non_integer_amount", "cost": {}}
	var amount: int = raw_amount
	if amount < 0:
		return {"ok": false, "error": "negative_amount", "cost": {}}
	return {"ok": true, "error": "", "cost": {"currency_id": currency_id, "amount": amount}}


static func can_pay(wallet: Dictionary, cost: Dictionary, currency_ids: Array) -> bool:
	var validation := validate_typed_cost(cost, currency_ids)
	if not bool(validation.get("ok", false)):
		return false
	var typed_cost: Dictionary = validation.get("cost", {})
	var amount := int(typed_cost.get("amount", 0))
	if amount <= 0:
		return true
	var entry: Dictionary = wallet.get(str(typed_cost.get("currency_id", "")), {})
	return int(entry.get("balance", -1)) >= amount


static func credit(wallet: Dictionary, currency_id: String, amount: int, currency_ids: Array) -> Dictionary:
	var next_wallet: Dictionary = wallet.duplicate(true)
	if not currency_ids.has(currency_id):
		return {"ok": false, "error": "unknown_currency", "wallet": next_wallet}
	if amount < 0:
		return {"ok": false, "error": "negative_amount", "wallet": next_wallet}
	if not next_wallet.has(currency_id):
		return {"ok": false, "error": "missing_wallet_entry", "wallet": next_wallet}
	var entry: Dictionary = next_wallet[currency_id]
	entry["balance"] = int(entry.get("balance", 0)) + amount
	entry["acquired"] = int(entry.get("acquired", 0)) + amount
	next_wallet[currency_id] = entry
	return {"ok": true, "error": "", "wallet": next_wallet}


static func spend(wallet: Dictionary, cost: Dictionary, currency_ids: Array) -> Dictionary:
	var next_wallet: Dictionary = wallet.duplicate(true)
	var validation := validate_typed_cost(cost, currency_ids)
	if not bool(validation.get("ok", false)):
		return {"ok": false, "error": str(validation.get("error", "invalid_cost")), "wallet": next_wallet}
	var typed_cost: Dictionary = validation.get("cost", {})
	var currency_id := str(typed_cost.get("currency_id", ""))
	var amount := int(typed_cost.get("amount", 0))
	if not next_wallet.has(currency_id):
		return {"ok": false, "error": "missing_wallet_entry", "wallet": next_wallet}
	var entry: Dictionary = next_wallet[currency_id]
	if int(entry.get("balance", 0)) < amount:
		return {"ok": false, "error": "insufficient_balance", "wallet": next_wallet}
	entry["balance"] = int(entry.get("balance", 0)) - amount
	entry["spent"] = int(entry.get("spent", 0)) + amount
	next_wallet[currency_id] = entry
	return {"ok": true, "error": "", "wallet": next_wallet}


static func ledger_is_valid(wallet: Dictionary, currency_ids: Array) -> bool:
	if wallet.size() != currency_ids.size():
		return false
	for raw_id in currency_ids:
		var currency_id := str(raw_id)
		if not wallet.has(currency_id):
			return false
		var entry: Dictionary = wallet[currency_id]
		var raw_balance: Variant = entry.get("balance", null)
		var raw_acquired: Variant = entry.get("acquired", null)
		var raw_spent: Variant = entry.get("spent", null)
		if typeof(raw_balance) != TYPE_INT or typeof(raw_acquired) != TYPE_INT or typeof(raw_spent) != TYPE_INT:
			return false
		var balance: int = raw_balance
		var acquired: int = raw_acquired
		var spent: int = raw_spent
		if balance < 0 or acquired < 0 or spent < 0 or acquired - spent != balance:
			return false
	return true


static func expected_drop_value(profile: Dictionary, multiplier: float = 1.0) -> float:
	if not bool(profile.get("drops_enabled", true)):
		return 0.0
	return maxf(0.0, float(profile.get("amount", 0)) * float(profile.get("chance", 0.0)) * maxf(0.0, multiplier))


static func currency_drops_enabled(round_index: int) -> bool:
	return round_index > 0 and round_index < MAX_ROUNDS


static func shop_rarity_weight(rarity: String, round_index: int) -> float:
	var progress := clampf(float(round_index - 1) / float(MAX_ROUNDS - 1), 0.0, 1.0)
	match rarity:
		"legendary":
			return 0.010 + progress * 0.035
		"rare":
			return 0.18 + progress * 0.14
		_:
			return 0.81 - progress * 0.13


static func scaled_shop_cost(base_cost: int, rarity: String, round_index: int) -> int:
	var scale := 1.0 + float(round_index - 1) * 0.075
	match rarity:
		"rare":
			scale *= 1.12
		"legendary":
			scale *= 1.24
	return int(max(1.0, round(float(base_cost) * scale)))


static func round_clear_reward(round_index: int) -> int:
	return int(ROUND_CLEAR_ORE_REWARDS.get(round_index, 0))


static func shop_reroll_cost(round_index: int, rounds_cleared: int) -> int:
	return max(2, int(round(2.0 + round_index * 0.65 + rounds_cleared * 0.25)))
