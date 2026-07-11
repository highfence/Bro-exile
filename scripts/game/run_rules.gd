extends RefCounted

const MAX_ROUNDS := 10
const CHECKPOINT_ROUNDS := [3, 5, 7]
const DEFAULT_BOSS_ROUND_DURATION := 120.0
const DEFAULT_SMOKE_ROUND_DURATION := 5.0


static func fresh_run_state() -> Dictionary:
	return {
		"checkpoint_round": 0,
		"selected_route": "",
		"persistent_risks": [],
		"elite_segment": {},
	}


static func reward_chain_for_round(round_index: int) -> Array:
	match round_index:
		1:
			return [{"type": "stat"}]
		2:
			return [{"type": "shop"}]
		3:
			return [{"type": "contract"}, {"type": "shop"}]
		4:
			return [{"type": "shop"}]
		5:
			return [{"type": "stat"}, {"type": "contract"}, {"type": "shop"}]
		6:
			return [{"type": "shop"}]
		7:
			return [{"type": "stat"}, {"type": "contract"}, {"type": "shop"}]
		8:
			return [{"type": "shop"}]
		9:
			return [{"type": "final_shop"}]
		_:
			return []


static func is_checkpoint_round(round_index: int) -> bool:
	return CHECKPOINT_ROUNDS.has(round_index)


static func round_duration(
	round_index: int,
	smoke_playtest: bool,
	smoke_duration: float = DEFAULT_SMOKE_ROUND_DURATION,
	boss_duration: float = DEFAULT_BOSS_ROUND_DURATION
) -> float:
	if smoke_playtest:
		return smoke_duration
	match round_index:
		1:
			return 25.0
		2:
			return 35.0
		3:
			return 45.0
		4:
			return 50.0
		5:
			return boss_duration
		6:
			return 55.0
		7:
			return 60.0
		8:
			return 65.0
		9:
			return 70.0
		10:
			return boss_duration
		_:
			return boss_duration


static func is_boss_round(round_index: int) -> bool:
	return round_index == 5 or round_index == 10


static func contract_enemy_hp_multiplier(kind: String, relic_counts: Dictionary) -> float:
	var multiplier := float(pow(1.08, _relic_count(relic_counts, "rough_vein")))
	if kind == "shield_zombie":
		multiplier *= float(pow(1.06, _relic_count(relic_counts, "cracked_shield_oath")))
	return multiplier


static func contract_enemy_damage_multiplier(kind: String, relic_counts: Dictionary) -> float:
	var multiplier := float(pow(1.05, _relic_count(relic_counts, "rough_vein")))
	if kind == "thrower":
		multiplier *= float(pow(1.08, _relic_count(relic_counts, "sharpened_throwing")))
	return multiplier


static func contract_enemy_speed_multiplier(kind: String, relic_counts: Dictionary) -> float:
	if kind == "fast_zombie":
		return float(pow(1.10, _relic_count(relic_counts, "overheated_footsteps")))
	return 1.0


static func contract_thrower_cooldown_multiplier(relic_counts: Dictionary) -> float:
	return float(pow(0.88, _relic_count(relic_counts, "sharpened_throwing")))


static func contract_elite_chance(kind: String, round_index: int, relic_counts: Dictionary) -> float:
	if _is_boss_type(kind) or kind == "elite_zombie":
		return 0.0
	var count := _relic_count(relic_counts, "chosen_prey")
	if count <= 0 or round_index < 4:
		return 0.0
	return min(0.24, 0.055 * float(count) + 0.025 * float(round_index - 4))


static func contract_ore_multiplier(enemy: Dictionary, relic_counts: Dictionary) -> float:
	var multiplier := 1.0
	var type := str(enemy.get("type", ""))
	if type == "fast_zombie":
		multiplier += 0.18 * float(_relic_count(relic_counts, "overheated_footsteps"))
	if type == "thrower":
		multiplier += 0.18 * float(_relic_count(relic_counts, "sharpened_throwing"))
	if type == "shield_zombie":
		multiplier += 0.20 * float(_relic_count(relic_counts, "cracked_shield_oath"))
	if type == "toxic_spider":
		multiplier += 0.20 * float(_relic_count(relic_counts, "viscous_poison_vein"))
	if type == "bomb_miner":
		multiplier += 0.22 * float(_relic_count(relic_counts, "shortened_fuse"))
	if bool(enemy.get("elite", false)):
		multiplier += 0.65 + 0.18 * float(_relic_count(relic_counts, "chosen_prey"))
	if _is_boss_type(type):
		multiplier += 0.25 * float(_relic_count(relic_counts, "awakened_overseer"))
	multiplier += 0.08 * float(_relic_count(relic_counts, "rough_vein"))
	return multiplier


static func _relic_count(relic_counts: Dictionary, id: String) -> int:
	return int(relic_counts.get(id, 0))


static func _is_boss_type(kind: String) -> bool:
	return kind == "boss" or kind == "mid_boss" or kind == "final_boss"
