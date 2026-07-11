extends RefCounted

const MAX_ROUNDS := 10
const ROUND_CLEAR_ORE_BASE := 20
const ROUND_CLEAR_ORE_STEP := 8


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
	return ROUND_CLEAR_ORE_BASE + round_index * ROUND_CLEAR_ORE_STEP


static func shop_reroll_cost(round_index: int, rounds_cleared: int) -> int:
	return max(2, int(round(2.0 + round_index * 0.65 + rounds_cleared * 0.25)))
