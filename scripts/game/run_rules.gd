extends RefCounted

const MAX_ROUNDS := 10
const CHECKPOINT_ROUNDS := [3, 5, 7]
const CHECKPOINT_ROUTE_IDS := ["safe", "risk", "shop", "elite"]
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
			return [{"type": "checkpoint"}]
		4:
			return [{"type": "shop"}]
		5:
			return [{"type": "stat"}, {"type": "checkpoint"}]
		6:
			return [{"type": "shop"}]
		7:
			return [{"type": "stat"}, {"type": "checkpoint"}]
		8:
			return [{"type": "shop"}]
		9:
			return [{"type": "final_shop"}]
		_:
			return []


static func is_checkpoint_round(round_index: int) -> bool:
	return CHECKPOINT_ROUNDS.has(round_index)


static func is_checkpoint_route(route_id: String) -> bool:
	return CHECKPOINT_ROUTE_IDS.has(route_id)


static func open_checkpoint(state: Dictionary, completed_round: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if not is_checkpoint_round(completed_round):
		return next_state
	if int(next_state.get("checkpoint_round", 0)) == completed_round and not str(next_state.get("selected_route", "")).is_empty():
		return next_state
	next_state["checkpoint_round"] = completed_round
	next_state["selected_route"] = ""
	return next_state


static func select_checkpoint_route(state: Dictionary, route_id: String, risk_id: String = "") -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var checkpoint_round := int(next_state.get("checkpoint_round", 0))
	if not is_checkpoint_round(checkpoint_round):
		return {"ok": false, "error": "checkpoint_not_open", "state": next_state}
	if not str(next_state.get("selected_route", "")).is_empty():
		return {"ok": false, "error": "checkpoint_already_selected", "state": next_state}
	if not is_checkpoint_route(route_id):
		return {"ok": false, "error": "checkpoint_route_unknown", "state": next_state}
	next_state["selected_route"] = route_id
	var history: Array = next_state.get("route_history", []).duplicate(true)
	history.append({"checkpoint_round": checkpoint_round, "route": route_id})
	next_state["route_history"] = history
	if route_id == "risk" and not risk_id.is_empty():
		next_state = attach_persistent_risk(next_state, risk_id)
	elif route_id == "elite":
		next_state["elite_segment"] = {
			"checkpoint_round": checkpoint_round,
			"start_round": checkpoint_round + 1,
			"end_round": checkpoint_segment_end(checkpoint_round),
			"status": "active",
		}
	return {"ok": true, "error": "", "state": next_state}


static func attach_persistent_risk(state: Dictionary, risk_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if risk_id.is_empty():
		return next_state
	var risks: Array = next_state.get("persistent_risks", []).duplicate(true)
	var entry := {"id": risk_id, "since_round": int(next_state.get("checkpoint_round", 0))}
	if not risks.has(entry):
		risks.append(entry)
	next_state["persistent_risks"] = risks
	return next_state


static func mark_elite_spawned(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var segment: Dictionary = next_state.get("elite_segment", {}).duplicate(true)
	if str(segment.get("status", "")) == "active":
		segment["spawned"] = true
		next_state["elite_segment"] = segment
	return next_state


static func complete_elite_objective(state: Dictionary, bonus: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var segment: Dictionary = next_state.get("elite_segment", {}).duplicate(true)
	if str(segment.get("status", "")) == "active":
		segment["status"] = "success"
		segment["bonus"] = bonus
		next_state["elite_segment"] = segment
		_append_elite_result(next_state, segment)
	return next_state


static func advance_checkpoint_state(state: Dictionary, current_round: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var segment: Dictionary = next_state.get("elite_segment", {}).duplicate(true)
	if str(segment.get("status", "")) == "active" and current_round > int(segment.get("end_round", 0)):
		segment["status"] = "missed"
		next_state["elite_segment"] = segment
		_append_elite_result(next_state, segment)
	return next_state


static func _append_elite_result(state: Dictionary, segment: Dictionary) -> void:
	var results: Array = state.get("elite_results", []).duplicate(true)
	results.append(segment.duplicate(true))
	state["elite_results"] = results


static func checkpoint_segment_end(checkpoint_round: int) -> int:
	match checkpoint_round:
		3:
			return 5
		5:
			return 7
		7:
			return MAX_ROUNDS
		_:
			return checkpoint_round + 1


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
