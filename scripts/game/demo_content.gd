extends RefCounted

const RunRulesScript = preload("res://scripts/game/run_rules.gd")

const STARTER_WEAPON_IDS := ["pickaxe", "nailgun", "lantern"]
const CURRENCY_IDS := ["ore", "catalyst", "forge_core"]
const NORMAL_ENEMY_TYPES := ["zombie", "fast_zombie", "spider", "thrower", "shield_zombie", "toxic_spider", "bomb_miner", "elite_zombie"]
const BASE_CONTRACT_IDS := ["overheated_footsteps", "sharpened_throwing", "rough_vein", "chosen_prey"]
const MID_CONTRACT_IDS := ["cracked_shield_oath", "viscous_poison_vein", "shortened_fuse"]
const LATE_CONTRACT_IDS := ["awakened_overseer"]

const CURRENCY_REGISTRY := {
	"ore": {
		"id": "ore", "name": "광석", "short_name": "광", "color": "#e6b85c", "shape": "diamond",
		"source_ids": ["common_enemy", "round_clear"], "sink_ids": ["shop_part", "shop_item"],
	},
	"catalyst": {
		"id": "catalyst", "name": "촉매", "short_name": "촉", "color": "#6cc3c0", "shape": "ring",
		"source_ids": ["threat_enemy"], "sink_ids": ["shop_reroll"],
	},
	"forge_core": {
		"id": "forge_core", "name": "강화핵", "short_name": "핵", "color": "#f0643b", "shape": "hex",
		"source_ids": ["elite_zombie", "checkpoint_elite", "mid_boss"], "sink_ids": ["weapon_temper"],
	},
}

const ENEMY_CURRENCY_PROFILES := {
	"zombie": {"primary_currency_id": "ore", "drop_weights": {"ore": 0.75, "catalyst": 0.10, "none": 0.15}, "currency_amounts": {"ore": 2, "catalyst": 1}, "drops_enabled": true},
	"fast_zombie": {"primary_currency_id": "catalyst", "drop_weights": {"ore": 0.30, "catalyst": 0.50, "none": 0.20}, "currency_amounts": {"ore": 1, "catalyst": 1}, "drops_enabled": true},
	"spider": {"primary_currency_id": "ore", "drop_weights": {"ore": 0.75, "catalyst": 0.10, "none": 0.15}, "currency_amounts": {"ore": 2, "catalyst": 1}, "drops_enabled": true},
	"thrower": {"primary_currency_id": "catalyst", "drop_weights": {"ore": 0.30, "catalyst": 0.50, "none": 0.20}, "currency_amounts": {"ore": 1, "catalyst": 2}, "drops_enabled": true},
	"shield_zombie": {"primary_currency_id": "ore", "drop_weights": {"ore": 0.75, "catalyst": 0.10, "none": 0.15}, "currency_amounts": {"ore": 3, "catalyst": 1}, "drops_enabled": true},
	"toxic_spider": {"primary_currency_id": "catalyst", "drop_weights": {"ore": 0.30, "catalyst": 0.50, "none": 0.20}, "currency_amounts": {"ore": 1, "catalyst": 1}, "drops_enabled": true},
	"bomb_miner": {"primary_currency_id": "catalyst", "drop_weights": {"ore": 0.30, "catalyst": 0.50, "none": 0.20}, "currency_amounts": {"ore": 1, "catalyst": 3}, "drops_enabled": true},
	"elite_zombie": {"primary_currency_id": "forge_core", "amount": 1, "chance": 1.0, "drops_enabled": true},
	"boss": {"primary_currency_id": "", "amount": 0, "chance": 0.0, "drops_enabled": false},
	"mid_boss": {"primary_currency_id": "forge_core", "amount": 2, "chance": 1.0, "drops_enabled": true},
	"final_boss": {"primary_currency_id": "", "amount": 0, "chance": 0.0, "drops_enabled": false},
}

const WEAPON_TEMPER_RECIPES := {
	"pickaxe": {
		"name": "곡괭이 담금질", "description": "타격점과 휘두름 폭을 함께 단련합니다.",
		"multipliers": {"damage": 1.14, "range": 1.04}, "max_rank": 3,
	},
	"nailgun": {
		"name": "네일건 압력 단련", "description": "못의 위력과 탄속을 높입니다.",
		"multipliers": {"damage": 1.16, "speed": 1.04}, "max_rank": 3,
	},
	"lantern": {
		"name": "랜턴 심지 단련", "description": "빛의 위력과 번지는 폭을 높입니다.",
		"multipliers": {"damage": 1.12, "range": 1.05}, "max_rank": 3,
	},
}


static func currency_ids() -> Array:
	return CURRENCY_IDS.duplicate()


static func currency_registry() -> Dictionary:
	return CURRENCY_REGISTRY.duplicate(true)


static func currency_definition(currency_id: String) -> Dictionary:
	return Dictionary(CURRENCY_REGISTRY.get(currency_id, {})).duplicate(true)


static func normal_enemy_types() -> Array:
	return NORMAL_ENEMY_TYPES.duplicate()


static func enemy_currency_profile(enemy_type: String) -> Dictionary:
	return Dictionary(ENEMY_CURRENCY_PROFILES.get(enemy_type, {})).duplicate(true)


static func weapon_temper_recipe(weapon_id: String) -> Dictionary:
	return Dictionary(WEAPON_TEMPER_RECIPES.get(weapon_id, {})).duplicate(true)


static func currency_contract_errors(registry_override: Dictionary = {}) -> Array[String]:
	var registry: Dictionary = CURRENCY_REGISTRY.duplicate(true) if registry_override.is_empty() else registry_override.duplicate(true)
	var errors: Array[String] = []
	for raw_id in CURRENCY_IDS:
		var currency_id := str(raw_id)
		if not registry.has(currency_id):
			errors.append("missing_currency:%s" % currency_id)
			continue
		var definition: Dictionary = registry[currency_id]
		if str(definition.get("id", "")) != currency_id:
			errors.append("currency_id_mismatch:%s" % currency_id)
		if Array(definition.get("source_ids", [])).is_empty():
			errors.append("currency_without_source:%s" % currency_id)
		if Array(definition.get("sink_ids", [])).is_empty():
			errors.append("currency_without_sink:%s" % currency_id)
		if str(definition.get("shape", "")).is_empty():
			errors.append("currency_without_shape:%s" % currency_id)
	for raw_type in NORMAL_ENEMY_TYPES:
		var enemy_type := str(raw_type)
		if not ENEMY_CURRENCY_PROFILES.has(enemy_type):
			errors.append("enemy_without_profile:%s" % enemy_type)
			continue
		var profile: Dictionary = ENEMY_CURRENCY_PROFILES[enemy_type]
		var primary_currency_id := str(profile.get("primary_currency_id", ""))
		if not CURRENCY_IDS.has(primary_currency_id):
			errors.append("enemy_invalid_primary:%s" % enemy_type)
		if primary_currency_id == "forge_core":
			if int(profile.get("amount", 0)) <= 0 or float(profile.get("chance", 0.0)) <= 0.0:
				errors.append("enemy_invalid_drop:%s" % enemy_type)
			continue
		var drop_weights: Dictionary = profile.get("drop_weights", {})
		var currency_amounts: Dictionary = profile.get("currency_amounts", {})
		var weight_total := 0.0
		for outcome_id in ["ore", "catalyst", "none"]:
			var weight := float(drop_weights.get(outcome_id, -1.0))
			if weight < 0.0:
				errors.append("enemy_invalid_weight:%s:%s" % [enemy_type, outcome_id])
			weight_total += maxf(0.0, weight)
		if not is_equal_approx(weight_total, 1.0):
			errors.append("enemy_invalid_weight_total:%s" % enemy_type)
		if float(drop_weights.get("none", 0.0)) <= 0.0:
			errors.append("enemy_without_no_drop:%s" % enemy_type)
		for currency_id in ["ore", "catalyst"]:
			if int(currency_amounts.get(currency_id, 0)) <= 0:
				errors.append("enemy_invalid_amount:%s:%s" % [enemy_type, currency_id])
	for weapon_id in STARTER_WEAPON_IDS:
		if not WEAPON_TEMPER_RECIPES.has(weapon_id):
			errors.append("weapon_without_temper:%s" % weapon_id)
	return errors


static func starter_weapon_ids() -> Array:
	return STARTER_WEAPON_IDS.duplicate()


static func contract_ids_for_round(round_index: int) -> Array:
	var ids := BASE_CONTRACT_IDS.duplicate()
	if round_index >= 5:
		ids.append_array(MID_CONTRACT_IDS)
	if round_index >= 7:
		ids.append_array(LATE_CONTRACT_IDS)
	return ids


static func checkpoint_route_ids() -> Array:
	return RunRulesScript.CHECKPOINT_ROUTE_IDS.duplicate()


static func checkpoint_route_options(completed_round: int) -> Array:
	var start_round := completed_round + 1
	var end_round := RunRulesScript.checkpoint_segment_end(completed_round)
	var scope := "R%d-R%d" % [start_round, end_round]
	return [
		{
			"id": "safe", "kind": "checkpoint_route", "name": "안전 정비",
			"desc": "전투 피해를 모두 회복하고 다음 구간으로 이동합니다.",
			"scope": scope, "danger": "위험 없음", "outcome": "완전 회복", "cost": 0,
		},
		{
			"id": "risk", "kind": "checkpoint_route", "name": "위험 계약",
			"desc": "누적되는 위험을 하나 받아 더 값진 적과 광맥을 만납니다.",
			"scope": "이번 런 지속", "danger": "지속 위험", "outcome": "계약 보상", "cost": 0,
		},
		{
			"id": "shop", "kind": "checkpoint_route", "name": "보급 상점",
			"desc": "회복 없이 현재 자원으로 장비를 정비합니다. 나가기는 무료입니다.",
			"scope": scope, "danger": "현재 체력 유지", "outcome": "구매 기회", "cost": 0,
		},
		{
			"id": "elite", "kind": "checkpoint_route", "name": "엘리트 추적",
			"desc": "다음 구간의 강적을 처치하면 희귀 강화 재료를 획득합니다.",
			"scope": scope, "danger": "강적 예약", "outcome": "강화 재료", "cost": 0,
		},
	]


static func round_brief(round_index: int) -> String:
	match round_index:
		2:
			return "색이 다른 빠른 좀비가 합류합니다. 거리를 더 자주 다시 잡아야 합니다."
		3:
			return "체력은 낮지만 4-5마리씩 몰려오는 거미떼가 합류합니다."
		4:
			return "원거리에서 돌을 던지는 좀비가 합류합니다. 투사체와 우선 처치 대상을 읽어야 합니다."
		5:
			return "중간 보스가 돌진, 장판, 방패 좀비 소환으로 후반 패턴을 예고합니다."
		6:
			return "방패 좀비가 일반 웨이브에 섞입니다. 정면을 고집하면 피해가 잘 들어가지 않습니다."
		7:
			return "독 거미가 죽으며 독 장판을 남깁니다. 이동 경로가 잠깐 망가집니다."
		8:
			return "자폭 광부가 전조 후 짧게 돌진합니다. 거리를 읽고 밀어내야 합니다."
		9:
			return "후반 위협이 함께 몰립니다. 최종 준비 상점 전 마지막 광맥입니다."
		10:
			return "최종 보스가 돌진, 장판, 소환, 탄막을 체력 페이즈에 따라 확장합니다."
		_:
			return "다음 라운드를 시작합니다."


static func next_round_warning_text(round_index: int) -> String:
	match round_index:
		2:
			return "다음 광맥: 빨라진 발소리"
		3:
			return "다음 광맥: 몰려오는 거미떼"
		4:
			return "다음 광맥: 날아오는 돌"
		5:
			return "다음 광맥: 중간 우두머리"
		6:
			return "다음 광맥: 방패를 든 무리"
		7:
			return "다음 광맥: 독 흔적"
		8:
			return "다음 광맥: 불안정한 폭약 냄새"
		9:
			return "다음 광맥: 후반 압박"
		10:
			return "다음 광맥: 최종 우두머리"
		_:
			return "다음 광맥: 미확인"
