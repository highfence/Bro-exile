extends Node

const RunRulesScript = preload("res://scripts/game/run_rules.gd")
const EconomyRulesScript = preload("res://scripts/game/economy_rules.gd")
const DemoContentScript = preload("res://scripts/game/demo_content.gd")

const BASELINE_FIXTURE := "baseline"
const RULE_IDS := ["run", "economy", "content"]

var _failures: Array[String] = []
var _state_dump := {}


func _ready() -> void:
	_run_harness.call_deferred()


func _run_harness() -> void:
	var request := _parse_request()
	var rule_id := str(request.get("rule", "all"))
	var fixture_id := str(request.get("fixture", BASELINE_FIXTURE))
	_state_dump = {"request": request, "results": {}}

	if fixture_id != BASELINE_FIXTURE:
		_fail("missing_fixture", {"fixture": fixture_id, "available": [BASELINE_FIXTURE]})
		_finish()
		return
	if rule_id != "all" and not RULE_IDS.has(rule_id):
		_fail("unknown_rule", {"rule": rule_id, "available": RULE_IDS})
		_finish()
		return

	if rule_id == "all" or rule_id == "run":
		_validate_run_rules()
	if rule_id == "all" or rule_id == "economy":
		_validate_economy_rules()
	if rule_id == "all" or rule_id == "content":
		_validate_demo_content()
	_finish()


func _parse_request() -> Dictionary:
	var request := {"rule": "all", "fixture": BASELINE_FIXTURE}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rule="):
			request.rule = arg.trim_prefix("--rule=")
		elif arg.begins_with("--fixture="):
			request.fixture = arg.trim_prefix("--fixture=")
	return request


func _validate_run_rules() -> void:
	var expected_routes := [
		"stat",
		"shop",
		"checkpoint",
		"shop",
		"stat -> checkpoint",
		"shop",
		"stat -> checkpoint",
		"shop",
		"final_shop",
		"victory",
	]
	var actual_routes: Array[String] = []
	for round_index in range(1, RunRulesScript.MAX_ROUNDS + 1):
		actual_routes.append(_reward_route_label(RunRulesScript.reward_chain_for_round(round_index)))
	_expect_equal("run.reward_routes", actual_routes, expected_routes)

	var checkpoint_rounds: Array[int] = []
	for round_index in range(1, RunRulesScript.MAX_ROUNDS + 1):
		if RunRulesScript.is_checkpoint_round(round_index):
			checkpoint_rounds.append(round_index)
	_expect_equal("run.checkpoint_cadence", checkpoint_rounds, [3, 5, 7])
	_expect_equal("run.round_5_duration", RunRulesScript.round_duration(5, false), 120.0)
	_expect_equal("run.round_10_is_boss", RunRulesScript.is_boss_round(10), true)
	_expect_equal("run.checkpoint_route_ids", DemoContentScript.checkpoint_route_ids(), ["safe", "risk", "shop", "elite"])

	var checkpoint_state: Dictionary = RunRulesScript.open_checkpoint(RunRulesScript.fresh_run_state(), 3)
	_expect_equal("run.checkpoint_opened", checkpoint_state.get("checkpoint_round", 0), 3)
	var risk_result: Dictionary = RunRulesScript.select_checkpoint_route(checkpoint_state, "risk")
	_expect_equal("run.risk_selected", risk_result.get("ok", false), true)
	var risk_state: Dictionary = RunRulesScript.attach_persistent_risk(risk_result.get("state", {}), "rough_vein")
	_expect_equal("run.risk_persists", risk_state.get("persistent_risks", []), [{"id": "rough_vein", "since_round": 3}])
	var locked_result: Dictionary = RunRulesScript.select_checkpoint_route(risk_state, "safe")
	_expect_equal("run.checkpoint_immutable", locked_result.get("error", ""), "checkpoint_already_selected")
	var elite_state: Dictionary = RunRulesScript.open_checkpoint(RunRulesScript.fresh_run_state(), 5)
	var elite_result: Dictionary = RunRulesScript.select_checkpoint_route(elite_state, "elite")
	_expect_equal("run.elite_selected", elite_result.get("ok", false), true)
	_expect_equal("run.elite_segment", Dictionary(elite_result.get("state", {})).get("elite_segment", {}), {
		"checkpoint_round": 5,
		"start_round": 6,
		"end_round": 7,
		"status": "active",
	})
	var expired_state: Dictionary = RunRulesScript.advance_checkpoint_state(elite_result.get("state", {}), 8)
	_expect_equal("run.elite_expires", Dictionary(expired_state.get("elite_segment", {})).get("status", ""), "missed")

	var reset_state: Dictionary = RunRulesScript.fresh_run_state()
	_expect_equal("run.reset_state", reset_state, {
		"checkpoint_round": 0,
		"selected_route": "",
		"persistent_risks": [],
		"elite_segment": {},
	})

	var relic_counts := {"rough_vein": 2, "cracked_shield_oath": 1, "chosen_prey": 3}
	_expect_near("run.contract_hp", RunRulesScript.contract_enemy_hp_multiplier("shield_zombie", relic_counts), pow(1.08, 2) * 1.06)
	_expect_near("run.contract_elite_chance", RunRulesScript.contract_elite_chance("zombie", 7, relic_counts), 0.24)
	_state_dump.results.run = {
		"routes": actual_routes,
		"checkpoint_rounds": checkpoint_rounds,
		"reset_state": reset_state,
		"risk_state": risk_state,
		"elite_expired_state": expired_state,
	}


func _validate_economy_rules() -> void:
	var currency_ids: Array = DemoContentScript.currency_ids()
	var fresh_wallet: Dictionary = EconomyRulesScript.fresh_wallet(currency_ids)
	_expect_equal("economy.fresh_wallet", fresh_wallet, {
		"ore": {"balance": 0, "acquired": 0, "spent": 0},
		"catalyst": {"balance": 0, "acquired": 0, "spent": 0},
		"forge_core": {"balance": 0, "acquired": 0, "spent": 0},
	})
	var unknown_credit: Dictionary = EconomyRulesScript.credit(fresh_wallet, "unknown", 1, currency_ids)
	_expect_equal("economy.unknown_credit_error", unknown_credit.get("error", ""), "unknown_currency")
	_expect_equal("economy.unknown_credit_unchanged", unknown_credit.get("wallet", {}), fresh_wallet)
	var negative_cost: Dictionary = EconomyRulesScript.validate_typed_cost({"currency_id": "ore", "amount": -1}, currency_ids)
	_expect_equal("economy.negative_cost", negative_cost.get("error", ""), "negative_amount")
	var fractional_cost: Dictionary = EconomyRulesScript.validate_typed_cost({"currency_id": "ore", "amount": 1.5}, currency_ids)
	_expect_equal("economy.fractional_cost", fractional_cost.get("error", ""), "non_integer_amount")
	var negative_fractional_cost: Dictionary = EconomyRulesScript.validate_typed_cost({"currency_id": "ore", "amount": -0.5}, currency_ids)
	_expect_equal("economy.negative_fractional_cost", negative_fractional_cost.get("error", ""), "non_integer_amount")
	var credited: Dictionary = EconomyRulesScript.credit(fresh_wallet, "ore", 3, currency_ids)
	var exact_spend: Dictionary = EconomyRulesScript.spend(credited.get("wallet", {}), {"currency_id": "ore", "amount": 3}, currency_ids)
	_expect_equal("economy.exact_cost", Dictionary(exact_spend.get("wallet", {})).get("ore", {}), {"balance": 0, "acquired": 3, "spent": 3})
	_expect_equal("economy.exact_cost_invariant", EconomyRulesScript.ledger_is_valid(exact_spend.get("wallet", {}), currency_ids), true)
	var fractional_ledger: Dictionary = exact_spend.get("wallet", {}).duplicate(true)
	Dictionary(fractional_ledger["ore"])["balance"] = 0.0
	_expect_equal("economy.fractional_ledger_invalid", EconomyRulesScript.ledger_is_valid(fractional_ledger, currency_ids), false)
	var one_short: Dictionary = EconomyRulesScript.spend(credited.get("wallet", {}), {"currency_id": "ore", "amount": 4}, currency_ids)
	_expect_equal("economy.one_short_error", one_short.get("error", ""), "insufficient_balance")
	_expect_equal("economy.one_short_unchanged", one_short.get("wallet", {}), credited.get("wallet", {}))
	_expect_equal("economy.round_10_drops_disabled", EconomyRulesScript.currency_drops_enabled(10), false)
	_expect_equal("economy.round_9_drops_enabled", EconomyRulesScript.currency_drops_enabled(9), true)
	var catalyst_profile: Dictionary = DemoContentScript.enemy_currency_profile("fast_zombie")
	_expect_near("economy.safe_expected_catalyst", EconomyRulesScript.expected_drop_value(catalyst_profile, 1.0), 1.0)
	_expect_near("economy.risk_expected_catalyst", EconomyRulesScript.expected_drop_value(catalyst_profile, 1.18), 1.18)
	var representative_counts := {"zombie": 3, "spider": 6, "shield_zombie": 6}
	var expected_enemy_ore := 0.0
	for enemy_type in representative_counts.keys():
		expected_enemy_ore += EconomyRulesScript.expected_drop_value(DemoContentScript.enemy_currency_profile(str(enemy_type))) * int(representative_counts[enemy_type])
	var fixed_round_ore := 0
	for round_index in range(1, 10):
		fixed_round_ore += EconomyRulesScript.round_clear_reward(round_index)
	var fixed_share := float(fixed_round_ore) / (float(fixed_round_ore) + expected_enemy_ore)
	_expect_equal("economy.fixed_ore_share_under_40", fixed_share <= 0.40, true)
	var first_shop_budget := EconomyRulesScript.round_clear_reward(1) + EconomyRulesScript.round_clear_reward(2) + 4
	_expect_equal("economy.first_shop_common_budget", first_shop_budget >= 15 and first_shop_budget <= 18, true)
	var first_run_target_catalyst := EconomyRulesScript.expected_drop_value(catalyst_profile) * 2.0
	var second_run_target_catalyst := EconomyRulesScript.expected_drop_value(catalyst_profile) * 6.0
	var first_run_unrelated_ore := EconomyRulesScript.expected_drop_value(DemoContentScript.enemy_currency_profile("zombie")) * 6.0
	var second_run_unrelated_ore := EconomyRulesScript.expected_drop_value(DemoContentScript.enemy_currency_profile("zombie")) * 6.0
	_expect_equal("economy.discovery_proxy_target_increases", second_run_target_catalyst > first_run_target_catalyst, true)
	_expect_near("economy.discovery_proxy_unrelated_stable", second_run_unrelated_ore, first_run_unrelated_ore)
	_expect_near("economy.common_weight_r1", EconomyRulesScript.shop_rarity_weight("common", 1), 0.81)
	_expect_near("economy.rare_weight_r10", EconomyRulesScript.shop_rarity_weight("rare", 10), 0.32)
	_expect_near("economy.legendary_weight_r10", EconomyRulesScript.shop_rarity_weight("legendary", 10), 0.045)
	_expect_equal("economy.common_cost_r1", EconomyRulesScript.scaled_shop_cost(16, "common", 1), 16)
	_expect_equal("economy.legendary_cost_r10", EconomyRulesScript.scaled_shop_cost(76, "legendary", 10), 158)
	_expect_equal("economy.round_clear_r1", EconomyRulesScript.round_clear_reward(1), 6)
	_expect_equal("economy.round_clear_r2", EconomyRulesScript.round_clear_reward(2), 6)
	_expect_equal("economy.round_clear_r3", EconomyRulesScript.round_clear_reward(3), 0)
	_expect_equal("economy.reroll_cost", EconomyRulesScript.shop_reroll_cost(3, 2), 4)
	_state_dump.results.economy = {
		"wallet": exact_spend.get("wallet", {}),
		"weights_r10": {
			"common": EconomyRulesScript.shop_rarity_weight("common", 10),
			"rare": EconomyRulesScript.shop_rarity_weight("rare", 10),
			"legendary": EconomyRulesScript.shop_rarity_weight("legendary", 10),
		},
		"round_clear_r3": EconomyRulesScript.round_clear_reward(3),
		"fixed_ore_share": fixed_share,
		"first_shop_budget": first_shop_budget,
		"discovery_proxy": {"first_catalyst": first_run_target_catalyst, "second_catalyst": second_run_target_catalyst, "ore_each": first_run_unrelated_ore},
	}


func _validate_demo_content() -> void:
	_expect_equal("content.currency_ids", DemoContentScript.currency_ids(), ["ore", "catalyst", "forge_core"])
	_expect_equal("content.currency_contract", DemoContentScript.currency_contract_errors(), [])
	_expect_equal("content.zombie_ore_profile", DemoContentScript.enemy_currency_profile("zombie"), {"primary_currency_id": "ore", "amount": 2, "chance": 1.0, "drops_enabled": true})
	_expect_equal("content.spider_ore_profile", DemoContentScript.enemy_currency_profile("spider"), {"primary_currency_id": "ore", "amount": 2, "chance": 1.0, "drops_enabled": true})
	var sinkless_registry: Dictionary = DemoContentScript.currency_registry()
	Dictionary(sinkless_registry["catalyst"])["sink_ids"] = []
	_expect_equal("content.sinkless_currency", DemoContentScript.currency_contract_errors(sinkless_registry).has("currency_without_sink:catalyst"), true)
	for enemy_type in DemoContentScript.normal_enemy_types():
		var profile: Dictionary = DemoContentScript.enemy_currency_profile(str(enemy_type))
		_expect_equal("content.enemy_primary.%s" % enemy_type, DemoContentScript.currency_ids().has(str(profile.get("primary_currency_id", ""))), true)
	_expect_equal("content.final_boss_terminal_only", DemoContentScript.enemy_currency_profile("final_boss").get("drops_enabled", true), false)
	_expect_equal("content.pickaxe_temper", DemoContentScript.weapon_temper_recipe("pickaxe").get("multipliers", {}), {"damage": 1.14, "range": 1.04})
	_expect_equal("content.nailgun_temper", DemoContentScript.weapon_temper_recipe("nailgun").get("multipliers", {}), {"damage": 1.16, "speed": 1.04})
	_expect_equal("content.lantern_temper", DemoContentScript.weapon_temper_recipe("lantern").get("multipliers", {}), {"damage": 1.12, "range": 1.05})
	_expect_equal("content.starter_weapons", DemoContentScript.starter_weapon_ids(), ["pickaxe", "nailgun", "lantern"])
	_expect_equal("content.contracts_r3", DemoContentScript.contract_ids_for_round(3), [
		"overheated_footsteps",
		"sharpened_throwing",
		"rough_vein",
		"chosen_prey",
	])
	_expect_equal("content.contracts_r7_count", DemoContentScript.contract_ids_for_round(7).size(), 8)
	_expect_equal("content.round_10_warning", DemoContentScript.next_round_warning_text(10), "다음 광맥: 최종 우두머리")
	_state_dump.results.content = {
		"currency_ids": DemoContentScript.currency_ids(),
		"starter_weapons": DemoContentScript.starter_weapon_ids(),
		"contracts_r7": DemoContentScript.contract_ids_for_round(7),
	}


func _reward_route_label(chain: Array) -> String:
	var labels := PackedStringArray()
	for step in chain:
		labels.append(str(Dictionary(step).get("type", "")))
	return " -> ".join(labels) if not labels.is_empty() else "victory"


func _expect_equal(id: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		_fail(id, {"actual": actual, "expected": expected})


func _expect_near(id: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		_fail(id, {"actual": actual, "expected": expected})


func _fail(id: String, details: Dictionary) -> void:
	_failures.append(id)
	_state_dump[id] = details


func _finish() -> void:
	if _failures.is_empty():
		print("DEMO_RULE_HARNESS_PASS state=%s" % JSON.stringify(_state_dump))
		get_tree().quit(0)
		return
	print("DEMO_RULE_HARNESS_FAIL failures=%s state=%s" % [str(_failures), JSON.stringify(_state_dump)])
	get_tree().quit(1)
