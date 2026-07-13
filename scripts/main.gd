extends Node2D

const GameUIScript = preload("res://scripts/ui/game_ui.gd")
const OreUIThemeScript = preload("res://scripts/ui/ore_ui_theme.gd")
const RunRulesScript = preload("res://scripts/game/run_rules.gd")
const EconomyRulesScript = preload("res://scripts/game/economy_rules.gd")
const DemoContentScript = preload("res://scripts/game/demo_content.gd")

const VIEW_SIZE := Vector2(1280, 720)
const WORLD_SIZE := Vector2(2048, 2048)
const WORLD_MARGIN := 34.0
const MODE_START := "start"
const MODE_PLAY := "play"
const MODE_CHOICE := "choice"
const MODE_GAME_OVER := "game_over"
const MODE_VICTORY := "victory"
const MAX_ROUNDS := RunRulesScript.MAX_ROUNDS
const MAX_WEAPON_SLOTS := 6
const MAX_WEAPON_LEVEL := 4
const SHOP_OPTION_COUNT := 4
const RELIC_OPTION_COUNT := 3
const P1_ROUND_DURATION := 42.0
const P1_BOSS_ROUND_DURATION := 120.0
const P2_SHOP_REWARDS_ENABLED := true
const P2_LEVEL_UP_REWARDS_ENABLED := false
const SMOKE_ROUND_DURATION := 5.0
const SMOKE_PLAYTEST_DURATION := 130.0
const SMOKE_PLAYTEST_CAPTURE_PATH := "/private/tmp/orebound-godot-playtest.png"
const RUN_REPORT_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-run-report-ui.png"
const COMBAT_FEEDBACK_CAPTURE_PATH := "/private/tmp/orebound-godot-combat-feedback.png"
const P6_MAP_CAMERA_CAPTURE_PATH := "/private/tmp/orebound-godot-p6-map-camera.png"
const SPAWN_TELEGRAPH_CAPTURE_PATH := "/private/tmp/orebound-godot-spawn-telegraph.png"
const PAUSE_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-pause-ui.png"
const CHOICE_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-choice-ui.png"
const SHOP_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-shop-ui.png"
const RELIC_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-relic-ui.png"
const STAGE1_CAPTURE_PATH := "/private/tmp/orebound-godot-stage1.png"
const MONSTER_ROSTER_CAPTURE_PATH := "/private/tmp/orebound-godot-monster-roster.png"
const P7_SHOP_RARITY_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-p7-shop-rarity-ui.png"
const P7_CONTRACT_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-p7-contract-ui.png"
const P7_BOSS_PATTERNS_CAPTURE_PATH := "/private/tmp/orebound-godot-p7-boss-patterns.png"
const P7_GAME_OVER_SUMMARY_CAPTURE_PATH := "/private/tmp/orebound-godot-p7-game-over-summary.png"
const P8_WEAPON_SELECT_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-p8-weapon-select-ui.png"
const P8_SHOP_WEAPON_PARTS_CAPTURE_PATH := "/private/tmp/orebound-godot-p8-shop-weapon-parts.png"
const P8_PICKAXE_SWING_CAPTURE_PATH := "/private/tmp/orebound-godot-p8-pickaxe-swing.png"
const CHECKPOINT_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-checkpoint-ui.png"
const CHECKPOINT_HUD_CAPTURE_PATH := "/private/tmp/orebound-godot-checkpoint-hud.png"
const CHECKPOINT_ELITE_CORE_BONUS := 1
const BOSS_POOL_RADIUS := 128.0
const PLAYER_VISUAL_SCALE := 0.27
const ZOMBIE_VISUAL_SCALE := 0.25
const PLAYER_IDLE_PERIOD := 1.32
const PLAYER_MOVE_PERIOD := 0.52
const ZOMBIE_IDLE_PERIOD := 1.46
const ZOMBIE_MOVE_PERIOD := 0.72
const PLAYER_CORE_BODY_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/core_body.png"
const PLAYER_LEFT_GLOVE_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/left_glove.png"
const PLAYER_RIGHT_GLOVE_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/right_glove.png"
const PLAYER_LEFT_BOOT_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/left_boot.png"
const PLAYER_RIGHT_BOOT_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/right_boot.png"
const ZOMBIE_IDLE_PATH := "res://assets/sprites/characters/miner_zombie_v1/zombie_idle.png"
const FAST_ZOMBIE_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v2/fast_zombie.png"
const SPIDER_SWARM_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v1/spider_swarm.png"
const THROWER_ZOMBIE_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v1/thrower_zombie.png"
const SHIELD_ZOMBIE_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v2/shield_zombie.png"
const BOSS_ZOMBIE_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v2/boss_zombie.png"
const PICKAXE_SWING_PATH := "res://assets/sprites/items/p8_weapons/weapon_pickaxe_swing.png"
const CAMERA_FOLLOW_SPEED := 7.5
const SPAWN_WARNING_DURATION := 0.78
const BOSS_SPAWN_WARNING_DURATION := 1.18
const ENEMY_EMERGE_DURATION := 0.32

var mode := MODE_START
var currency_ids: Array = DemoContentScript.currency_ids()
var currency_registry: Dictionary = DemoContentScript.currency_registry()
var elapsed := 0.0
var wave := 1
var wave_timer := 35.0
var spawn_timer := 0.0
var wallets := {}
var level := 1
var xp := 0.0
var xp_to_next := 18.0
var damage_multiplier := 1.0
var cooldown_multiplier := 1.0
var range_multiplier := 1.0
var currency_drop_multiplier := 1.0
var xp_multiplier := 1.0
var hp_regen := 0.0
var dash_cooldown := 0.0
var screen_shake := 0.0
var paused := false
var camera_pos := Vector2.ZERO
var draw_world_offset := Vector2.ZERO
var next_enemy_id := 1
var reroll_cost := 2
var round_currency_earned := {}
var rounds_cleared := 0
var spider_relic_packs_this_wave := 0
var debug_hurt_events := 0
var run_rerolls := 0
var run_purchase_count := 0
var run_round_clear_ore := 0
var run_purchase_names: Array = []
var run_rare_legendary_purchase_names: Array = []
var run_kill_count := 0
var run_kills_by_type := {}
var run_boss_damage := 0.0
var run_boss_defeated := false

var player := {}
var weapons: Array = []
var items: Array = []
var shop_stock: Array = []
var purchased_shop_item_ids: Array = []
var shop_seen_counts := {}
var shop_visit_seen_item_ids: Array = []
var active_relics: Array = []
var relic_counts := {}
var relic_seen_counts := {}
var pending_reward_chain: Array = []
var active_reward_context := {}
var enemies: Array = []
var bullets: Array = []
var enemy_projectiles: Array = []
var pickups: Array = []
var spawn_warnings: Array = []
var hazard_zones: Array = []
var sparks: Array = []
var floating_text: Array = []
var boss_spawned := false
var selected_weapon_id := ""
var run_rule_state := {}
var checkpoint_feedback_cache := PackedStringArray()
var checkpoint_feedback_dirty := true

var game_ui: CanvasLayer
var ui_font: Font
var active_choice_options: Array = []
var active_choice_method := ""
var active_choice_generation := 0
var handled_choice_keys := {}
var debug_currency_logging := false
var smoke_playtest := false
var smoke_elapsed := 0.0
var smoke_choices_taken := 0
var smoke_finishing := false
var smoke_weapon_id := ""
var player_core_body_texture: Texture2D
var player_left_glove_texture: Texture2D
var player_right_glove_texture: Texture2D
var player_left_boot_texture: Texture2D
var player_right_boot_texture: Texture2D
var zombie_idle_texture: Texture2D
var fast_zombie_texture: Texture2D
var spider_swarm_texture: Texture2D
var thrower_zombie_texture: Texture2D
var shield_zombie_texture: Texture2D
var boss_zombie_texture: Texture2D
var pickaxe_swing_texture: Texture2D

var stat_rewards := [
	{"id": "cooldown", "name": "손목 리듬 조정", "desc": "공격 속도가 아주 소폭 증가합니다.", "tag": "무료 체급 보정"},
	{"id": "range", "name": "거리 감각 보정", "desc": "현재 무기의 유효 범위가 아주 소폭 증가합니다.", "tag": "무료 체급 보정"},
	{"id": "speed", "name": "발걸음 정비", "desc": "이동 속도가 아주 소폭 증가합니다.", "tag": "무료 체급 보정"},
	{"id": "damage", "name": "타격점 보정", "desc": "피해량이 아주 소폭 증가합니다.", "tag": "무료 체급 보정"},
	{"id": "hp", "name": "흉곽 보강", "desc": "최대 체력이 아주 소폭 증가하고 체력을 조금 회복합니다.", "tag": "무료 체급 보정"},
	{"id": "armor", "name": "충격 흡수", "desc": "방어력이 아주 소폭 증가합니다.", "tag": "무료 체급 보정"},
	{"id": "regen", "name": "응급 호흡법", "desc": "라운드 중 미량 지속 회복이 아주 소폭 증가합니다.", "tag": "무료 체급 보정"},
]

var shop_catalog := [
	{"id": "lubricated_bearing", "kind": "part", "rarity": "common", "name": "윤활 베어링", "desc": "공격 속도 소폭 증가. 기본 화력을 안정적으로 끌어올립니다.", "cost": 16, "counter": "기본 화력", "icon": "res://assets/sprites/items/p2_parts/part_rapid_trigger.png", "weapon_stats": {"cooldown_mult": 0.91}},
	{"id": "extended_shaft", "kind": "part", "rarity": "common", "name": "연장 샤프트", "desc": "사거리 소폭 증가. 위험 패턴과 거리를 더 여유 있게 둡니다.", "cost": 16, "counter": "거리 확보", "icon": "res://assets/sprites/items/p2_parts/part_long_barrel.png", "weapon_stats": {"range_mult": 1.13, "speed_mult": 1.04}},
	{"id": "lightweight_grip", "kind": "item", "rarity": "common", "name": "경량 손잡이", "desc": "이동 속도 소폭 증가. 측면 이동과 장판 회피가 쉬워집니다.", "cost": 15, "counter": "기동 보정", "icon": "res://assets/sprites/items/p2_parts/part_spring_boots.png", "stats": {"speed_mult": 1.08}},
	{"id": "reinforced_bit", "kind": "part", "rarity": "common", "name": "강화 드릴촉", "desc": "피해량 소폭 증가. 모든 위협을 조금 더 빨리 정리합니다.", "cost": 17, "counter": "기본 피해", "icon": "res://assets/sprites/items/p2_parts/part_carbide_tip.png", "weapon_stats": {"damage_mult": 1.10}},
	{"id": "braced_breastplate", "kind": "item", "rarity": "common", "name": "보강 흉갑", "desc": "최대 체력 소폭 증가. 연속 실수에 버틸 여지를 만듭니다.", "cost": 16, "counter": "생존 보조", "icon": "res://assets/sprites/items/p2_parts/part_rations.png", "stats": {"max_hp_add": 14.0}},
	{"id": "emergency_compression_pack", "kind": "item", "rarity": "common", "name": "응급 압축팩", "desc": "라운드 중 미량 지속 회복. 오래 끌리는 구간을 보조합니다.", "cost": 18, "counter": "지속 회복", "icon": "res://assets/sprites/items/p2_parts/part_rations.png", "stats": {"regen_add": 0.22}},
	{"id": "reinforced_armor_plate", "kind": "item", "rarity": "common", "name": "보강 장갑판", "desc": "받는 피해 소폭 감소. 핵심 패턴 피해는 최소 피해를 남깁니다.", "cost": 18, "counter": "피해 완화", "icon": "res://assets/sprites/items/p2_parts/part_carbide_tip.png", "stats": {"armor_add": 0.8}},
	{"id": "piercing_bit", "kind": "part", "rarity": "rare", "name": "관통 드릴촉", "desc": "드릴촉 관통 +1. 방패 라인과 거미떼를 한 줄로 뚫습니다.", "cost": 34, "counter": "방패/무리 대응", "counters": [5, 6, 7], "icon": "res://assets/sprites/items/p2_parts/part_piercing_bit.png", "weapon_stats": {"pierce_add": 1.0, "damage_mult": 1.03}},
	{"id": "explosive_core", "kind": "part", "rarity": "rare", "name": "폭약 코어", "desc": "명중 지점에 작은 폭발을 붙입니다. 거미떼와 밀집 적 대응책입니다.", "cost": 38, "counter": "밀집 적 대응", "counters": [7, 8], "icon": "res://assets/sprites/items/p2_parts/part_shatter_charge.png", "weapon_stats": {"splash_add": 44.0, "damage_mult": 0.96}},
	{"id": "armor_shredding_blade", "kind": "part", "rarity": "rare", "name": "장갑 파쇄날", "desc": "방어 관통 +3. 방패 좀비와 보스 방어를 뚫습니다.", "cost": 40, "counter": "방어 관통", "counters": [5, 10], "icon": "res://assets/sprites/items/p2_parts/part_carbide_tip.png", "weapon_stats": {"armor_pierce_add": 3.0, "damage_mult": 1.05}},
	{"id": "recoil_spring", "kind": "part", "rarity": "rare", "name": "반동 스프링", "desc": "넉백 강화와 탄속 증가. 자폭 광부와 빠른 좀비를 밀어냅니다.", "cost": 35, "counter": "돌진 대응", "counters": [8, 9], "icon": "res://assets/sprites/items/p2_parts/part_rapid_trigger.png", "weapon_stats": {"knockback_add": 42.0, "speed_mult": 1.10}},
	{"id": "double_drill_chamber", "kind": "part", "rarity": "legendary", "unique": true, "name": "쌍열 드릴 챔버", "desc": "드릴촉을 한 발 더 발사합니다. 피해는 조금 보정되지만 빌드 방향을 크게 바꿉니다.", "cost": 76, "counter": "전설 변수", "icon": "res://assets/sprites/items/p2_parts/part_piercing_bit.png", "weapon_stats": {"projectiles_add": 1.0, "spread_add": 0.16, "damage_mult": 0.88, "center_projectile": true}},
]

var relic_catalog := [
	{
		"id": "overheated_footsteps",
		"kind": "relic",
		"name": "과열된 발걸음",
		"desc": "빠른 좀비가 더 빠르게 파고듭니다.",
		"danger": "빠른 좀비 속도 강화",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_spider_egg_fossil.png",
	},
	{
		"id": "sharpened_throwing",
		"kind": "relic",
		"name": "날카로운 투척",
		"desc": "투척 좀비의 돌이 더 빠르고 아프게 날아옵니다.",
		"danger": "투척 좀비 투사체 강화",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_hungry_lantern.png",
	},
	{
		"id": "rough_vein",
		"kind": "relic",
		"name": "거친 광맥",
		"desc": "일반 몹의 체력과 피해가 소폭 증가합니다.",
		"danger": "기본 몹 체급 강화",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_echoing_stone_heart.png",
	},
	{
		"id": "chosen_prey",
		"kind": "relic",
		"name": "선별된 사냥감",
		"desc": "일부 기존 몹이 엘리트로 승급합니다.",
		"danger": "엘리트 승급",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_red_vein_sample.png",
	},
	{
		"id": "cracked_shield_oath",
		"kind": "relic",
		"name": "금 간 방패의 맹세",
		"desc": "방패 좀비의 정면 방어가 더 단단해집니다.",
		"danger": "방패 정면 방어 강화",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_black_shell.png",
	},
	{
		"id": "viscous_poison_vein",
		"kind": "relic",
		"name": "질척이는 독맥",
		"desc": "독 장판이 더 오래 남아 이동 경로를 막습니다.",
		"danger": "독 장판 유지 시간 강화",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_twin_excavation_seal.png",
	},
	{
		"id": "shortened_fuse",
		"kind": "relic",
		"name": "짧아진 도화선",
		"desc": "자폭 광부의 돌진 전조가 더 짧아집니다.",
		"danger": "자폭 광부 전조 감소",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_unstable_blast_crystal.png",
	},
	{
		"id": "awakened_overseer",
		"kind": "relic",
		"name": "깨어난 우두머리",
		"desc": "보스 패턴 사이 간격이 더 짧아집니다.",
		"danger": "보스 패턴 간격 강화",
		"reward_hint": "더 큰 위험은 더 값진 성장 기회를 품는다.",
		"icon": "res://assets/sprites/items/p3_relics/relic_unstable_blast_crystal.png",
	},
]

var starter_weapon_ids: Array = DemoContentScript.starter_weapon_ids()

var weapon_catalog := {
	"pickaxe": {"name": "곡괭이", "family": "근접", "feel": "짧은 전방 부채꼴 휘두르기", "strength": "보스 딜타임과 가까운 적 정리", "weakness": "포위와 원거리 투척 압박", "fire_type": "pickaxe_slash", "cooldown": 1.05, "damage": 35.0, "range": 124.0, "speed": 0.0, "color": Color("#f2cf66"), "pierce": 0, "projectiles": 1, "spread": 0.28, "splash": 0.0, "armor_pierce": 0.0, "knockback": 16.0, "shape": "pickaxe", "icon": "res://assets/sprites/items/p8_weapons/weapon_pickaxe.png"},
	"nailgun": {"name": "네일건", "family": "원거리", "feel": "빠른 직선 못 투사체", "strength": "빠른 적과 투척 적 선제 처리", "weakness": "거미떼와 방패 정면", "fire_type": "bullet", "cooldown": 0.62, "damage": 15.0, "range": 360.0, "speed": 920.0, "color": Color("#d8f3ff"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0, "armor_pierce": 0.0, "knockback": 6.0, "shape": "nail", "icon": "res://assets/sprites/items/p8_weapons/weapon_nailgun.png"},
	"lantern": {"name": "랜턴", "family": "마법/장비", "feel": "쿨다운마다 번지는 주변 빛 펄스", "strength": "거미떼와 밀집 적, 동선 만들기", "weakness": "단일 보스딜과 원거리 투척 적", "fire_type": "lantern_pulse", "cooldown": 1.35, "damage": 17.0, "range": 158.0, "speed": 0.0, "color": Color("#e6b85c"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0, "armor_pierce": 0.0, "knockback": 4.0, "shape": "lantern", "icon": "res://assets/sprites/items/p8_weapons/weapon_lantern.png"},
	"drill_tip": {"name": "드릴촉 발사기", "family": "legacy/debug", "feel": "기존 직선 드릴촉", "strength": "기존 회귀 검증", "weakness": "D8 일반 스타터 아님", "fire_type": "bullet", "cooldown": 0.72, "damage": 16.0, "range": 430.0, "speed": 690.0, "color": Color("#d8ceb9"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0, "armor_pierce": 0.0, "knockback": 0.0, "shape": "drill_tip", "icon": "res://assets/sprites/items/p2_parts/part_piercing_bit.png"},
	"spitter": {"name": "광석 분사기", "fire_type": "bullet", "cooldown": 0.62, "damage": 18.0, "range": 470.0, "speed": 640.0, "color": Color("#e6b85c"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"flintlock": {"name": "쌍발 화승총", "fire_type": "bullet", "cooldown": 0.54, "damage": 9.0, "range": 390.0, "speed": 760.0, "color": Color("#f0643b"), "pierce": 0, "projectiles": 2, "spread": 0.20, "splash": 0.0},
	"drill": {"name": "파편 드릴", "fire_type": "bullet", "cooldown": 1.28, "damage": 34.0, "range": 560.0, "speed": 500.0, "color": Color("#93c96d"), "pierce": 3, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"coil": {"name": "전류 코일", "fire_type": "arc", "cooldown": 1.08, "damage": 16.0, "range": 180.0, "speed": 0.0, "color": Color("#6cc3c0"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"cleaver": {"name": "녹슨 절단기", "fire_type": "slash", "cooldown": 0.86, "damage": 23.0, "range": 132.0, "speed": 0.0, "color": Color("#d8ceb9"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"launcher": {"name": "광산 유탄기", "fire_type": "explosive", "cooldown": 1.48, "damage": 26.0, "range": 520.0, "speed": 430.0, "color": Color("#d87745"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 72.0},
}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	debug_currency_logging = args.has("--debug-u4-currency-contract")
	var checkpoint_smoke := _checkpoint_smoke_request(args)
	smoke_weapon_id = _weapon_arg_from_args(args)
	if bool(checkpoint_smoke.get("present", false)) or args.has("--smoke-playtest") or args.has("--debug-spider-relic-wave2") or args.has("--debug-boss-pierce-splash") or args.has("--debug-emerging-death-cleanup") or args.has("--debug-p7-reward-routes") or args.has("--debug-p7-shop-rarity") or args.has("--debug-p7-relic-contracts") or args.has("--debug-p7-boss-patterns") or args.has("--debug-p7-elite-marker") or args.has("--debug-p7-pause-cycle") or args.has("--debug-p7-legendary-aim") or args.has("--debug-p8-weapon-routes") or args.has("--debug-demo-rule-seams") or args.has("--debug-u3-balance-contract") or args.has("--debug-u4-currency-contract") or args.has("--capture-choice-ui") or args.has("--capture-shop-ui") or args.has("--capture-relic-ui") or args.has("--capture-run-report-ui") or args.has("--capture-combat-feedback") or args.has("--capture-p6-map-camera") or args.has("--capture-spawn-telegraph") or args.has("--capture-pause-ui") or args.has("--capture-stage1") or args.has("--capture-monster-roster") or args.has("--capture-p7-shop-rarity-ui") or args.has("--capture-p7-contract-ui") or args.has("--capture-p7-boss-patterns") or args.has("--capture-p7-game-over-summary") or args.has("--capture-p8-weapon-select-ui") or args.has("--capture-p8-shop-weapon-parts") or args.has("--capture-p8-pickaxe-swing") or args.has("--capture-checkpoint-ui"):
		seed(12345)
	else:
		randomize()
	_load_visual_textures()
	ui_font = OreUIThemeScript.load_font()
	_build_ui()
	_reset_run(false)
	_show_start_overlay()
	if args.has("--capture-ui"):
		_capture_ui_and_quit.call_deferred()
	elif args.has("--capture-choice-ui"):
		_capture_choice_ui_and_quit.call_deferred()
	elif args.has("--capture-shop-ui"):
		_capture_shop_ui_and_quit.call_deferred()
	elif args.has("--capture-relic-ui"):
		_capture_relic_ui_and_quit.call_deferred()
	elif args.has("--capture-run-report-ui"):
		_capture_run_report_ui_and_quit.call_deferred()
	elif args.has("--capture-combat-feedback"):
		_capture_combat_feedback_and_quit.call_deferred()
	elif args.has("--capture-p6-map-camera"):
		_capture_p6_map_camera_and_quit.call_deferred()
	elif args.has("--capture-spawn-telegraph"):
		_capture_spawn_telegraph_and_quit.call_deferred()
	elif args.has("--capture-pause-ui"):
		_capture_pause_ui_and_quit.call_deferred()
	elif args.has("--capture-stage1"):
		_capture_stage1_and_quit.call_deferred()
	elif args.has("--capture-monster-roster"):
		_capture_monster_roster_and_quit.call_deferred()
	elif args.has("--capture-p7-shop-rarity-ui"):
		_capture_p7_shop_rarity_ui_and_quit.call_deferred()
	elif args.has("--capture-p7-contract-ui"):
		_capture_p7_contract_ui_and_quit.call_deferred()
	elif args.has("--capture-p7-boss-patterns"):
		_capture_p7_boss_patterns_and_quit.call_deferred()
	elif args.has("--capture-p7-game-over-summary"):
		_capture_p7_game_over_summary_and_quit.call_deferred()
	elif args.has("--capture-p8-weapon-select-ui"):
		_capture_p8_weapon_select_ui_and_quit.call_deferred()
	elif args.has("--capture-p8-shop-weapon-parts"):
		_capture_p8_shop_weapon_parts_and_quit.call_deferred()
	elif args.has("--capture-p8-pickaxe-swing"):
		_capture_p8_pickaxe_swing_and_quit.call_deferred()
	elif args.has("--capture-checkpoint-ui"):
		_capture_checkpoint_ui_and_quit.call_deferred()
	elif bool(checkpoint_smoke.get("present", false)):
		_smoke_checkpoint_route_and_quit.call_deferred(str(checkpoint_smoke.get("route", "")))
	elif args.has("--smoke-playtest"):
		_start_smoke_playtest.call_deferred()
	elif args.has("--debug-spider-relic-wave2"):
		_debug_spider_relic_wave2_and_quit.call_deferred()
	elif args.has("--debug-boss-pierce-splash"):
		_debug_boss_pierce_splash_and_quit.call_deferred()
	elif args.has("--debug-emerging-death-cleanup"):
		_debug_emerging_death_cleanup_and_quit.call_deferred()
	elif args.has("--debug-p7-reward-routes"):
		_debug_p7_reward_routes_and_quit.call_deferred()
	elif args.has("--debug-p7-shop-rarity"):
		_debug_p7_shop_rarity_and_quit.call_deferred()
	elif args.has("--debug-p7-relic-contracts"):
		_debug_p7_relic_contracts_and_quit.call_deferred()
	elif args.has("--debug-p7-boss-patterns"):
		_debug_p7_boss_patterns_and_quit.call_deferred()
	elif args.has("--debug-p7-elite-marker"):
		_debug_p7_elite_marker_and_quit.call_deferred()
	elif args.has("--debug-p7-pause-cycle"):
		_debug_p7_pause_cycle_and_quit.call_deferred()
	elif args.has("--debug-p7-legendary-aim"):
		_debug_p7_legendary_aim_and_quit.call_deferred()
	elif args.has("--debug-p8-weapon-routes"):
		_debug_p8_weapon_routes_and_quit.call_deferred()
	elif args.has("--debug-demo-rule-seams"):
		_debug_demo_rule_seams_and_quit.call_deferred()
	elif args.has("--debug-u3-checkpoint-contract"):
		_debug_u3_checkpoint_contract_and_quit.call_deferred()
	elif args.has("--debug-u3-balance-contract"):
		_debug_u3_balance_contract_and_quit.call_deferred()
	elif args.has("--debug-u4-currency-contract"):
		_debug_u4_currency_contract_and_quit.call_deferred()


func _weapon_arg_from_args(args: PackedStringArray) -> String:
	for arg in args:
		if arg.begins_with("--weapon="):
			var id := arg.get_slice("=", 1)
			if starter_weapon_ids.has(id):
				return id
	return ""


func _checkpoint_smoke_request(args: PackedStringArray) -> Dictionary:
	for arg in args:
		if arg == "--smoke-checkpoint-route":
			return {"present": true, "route": ""}
		if arg.begins_with("--smoke-checkpoint-route="):
			return {"present": true, "route": arg.trim_prefix("--smoke-checkpoint-route=")}
	return {"present": false, "route": ""}


func _debug_u4_currency_contract_and_quit() -> void:
	_reset_run(false)
	_hide_overlay()
	mode = MODE_PLAY
	_equip_weapon_for_run("pickaxe")
	var failures := 0

	for enemy_type in ["zombie", "fast_zombie", "elite_zombie", "mid_boss"]:
		var enemy := _make_enemy(enemy_type)
		print("DEBUG_U4_SOURCE_PROFILE enemy=%s profile=%s" % [enemy_type, JSON.stringify(enemy.get("currency_drop", {}))])
		enemy["pos"] = player.get("pos", Vector2.ZERO)
		_drop_pickups(enemy)
	_collect_leftover_currency()
	if _currency_balance("ore") != 2 or _currency_balance("catalyst") != 1 or _currency_balance("forge_core") != 3:
		failures += 1

	_credit_currency("ore", 200)
	_credit_currency("catalyst", 8)
	_open_shop()
	var purchased_option: Dictionary = {}
	for option in active_choice_options:
		if ["part", "item"].has(str(Dictionary(option).get("kind", ""))) and not _choice_option_disabled(option):
			purchased_option = option
			break
	if purchased_option.is_empty():
		failures += 1
	else:
		var ore_spent_before := int(Dictionary(wallets.get("ore", {})).get("spent", 0))
		var canonical_cost := int(_option_cost(purchased_option).get("amount", 0))
		var forged_option := purchased_option.duplicate(true)
		forged_option["cost"] = _typed_cost("ore", 0)
		_on_ui_option_selected(forged_option)
		if int(Dictionary(wallets.get("ore", {})).get("spent", 0)) != ore_spent_before + canonical_cost:
			failures += 1
		var ore_after_purchase := _currency_balance("ore")
		_on_ui_option_selected(forged_option)
		if _currency_balance("ore") != ore_after_purchase:
			failures += 1
	if not _option_cost({"cost": 1}).is_empty():
		failures += 1

	var reroll_option := _active_choice_option_by_id("reroll")
	var catalyst_before := _currency_balance("catalyst")
	_on_ui_option_selected(reroll_option)
	if _currency_balance("catalyst") >= catalyst_before or run_rerolls != 1:
		failures += 1

	var target_before := _current_upgrade_target()
	var damage_before := float(target_before.get("damage", 0.0))
	var temper_option := _active_choice_option_by_id("temper_weapon")
	var core_before := _currency_balance("forge_core")
	_on_ui_option_selected(temper_option)
	var target_after := _current_upgrade_target()
	if int(target_after.get("upgrade_rank", 0)) != 1 or float(target_after.get("damage", 0.0)) <= damage_before or _currency_balance("forge_core") != core_before - 1:
		failures += 1
	weapons.append(Dictionary(weapons[0]).duplicate(true))
	if not _current_upgrade_target().is_empty() or _can_temper_current_weapon():
		failures += 1
	weapons.pop_back()

	wave = MAX_ROUNDS
	pickups.clear()
	_drop_pickups(_make_enemy("zombie"))
	if not pickups.is_empty():
		failures += 1
	if not EconomyRulesScript.ledger_is_valid(wallets, currency_ids):
		failures += 1
	var wallet_before_unknown := wallets.duplicate(true)
	pickups.append({"pos": player.get("pos", Vector2.ZERO), "radius": 6.0, "type": "currency", "currency_id": "unknown", "shape": "diamond", "value": 1, "color": Color.WHITE})
	_update_pickups(0.0)
	if wallets != wallet_before_unknown:
		failures += 1
	var death_balance_before := _currency_balance("ore")
	pickups.append({"pos": player.get("pos", Vector2.ZERO), "radius": 6.0, "type": "currency", "currency_id": "ore", "shape": "diamond", "value": 1, "color": Color("#e6b85c")})
	_game_over()
	if _currency_balance("ore") != death_balance_before:
		failures += 1
	pickups.clear()
	var state_before_reset := wallets.duplicate(true)
	for weapon_id in starter_weapon_ids:
		if not _debug_temper_recipe_route(str(weapon_id)):
			failures += 1
	_reset_run(false)
	for currency_id in currency_ids:
		if _currency_balance(str(currency_id)) != 0:
			failures += 1
	print("DEBUG_U4_CURRENCY_CONTRACT failures=%d before_reset=%s after_reset=%s" % [failures, JSON.stringify(state_before_reset), JSON.stringify(wallets)])
	get_tree().quit(1 if failures > 0 else 0)


func _debug_temper_recipe_route(weapon_id: String) -> bool:
	_reset_run(false)
	_hide_overlay()
	if not _equip_weapon_for_run(weapon_id):
		return false
	_credit_currency("forge_core", 6)
	var target_before := _current_upgrade_target().duplicate(true)
	_open_shop()
	for expected_rank in range(1, 4):
		var option := _active_choice_option_by_id("temper_weapon")
		if option.is_empty() or _choice_option_disabled(option):
			return false
		_on_ui_option_selected(option)
		if int(_current_upgrade_target().get("upgrade_rank", 0)) != expected_rank:
			return false
	var target_after := _current_upgrade_target()
	var capped_option := _active_choice_option_by_id("temper_weapon")
	if not _choice_option_disabled(capped_option) or _currency_balance("forge_core") != 0:
		return false
	var recipe := DemoContentScript.weapon_temper_recipe(weapon_id)
	var multipliers: Dictionary = recipe.get("multipliers", {})
	for stat_id in multipliers.keys():
		var expected := float(target_before.get(stat_id, 0.0)) * pow(float(multipliers[stat_id]), 3)
		if not is_equal_approx(float(target_after.get(stat_id, 0.0)), expected):
			return false
	if weapon_id == "nailgun" and (not is_equal_approx(float(target_after.get("range", 0.0)), float(target_before.get("range", 0.0))) or not is_equal_approx(float(target_after.get("cooldown", 0.0)), float(target_before.get("cooldown", 0.0)))):
		return false
	return Array(target_after.get("mods", [])).is_empty()


func _debug_spider_relic_wave2_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	wave = 2
	rounds_cleared = 1
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	enemies.clear()
	_add_relic(_relic_by_id("overheated_footsteps"))
	spider_relic_packs_this_wave = 0

	var event_counts := {}
	var spawn_events := 0
	while enemies.size() < _enemy_cap() and spawn_events < 40:
		var kind := _pick_enemy_kind()
		var pack_size := _enemy_pack_size(kind)
		event_counts[kind] = int(event_counts.get(kind, 0)) + 1
		_spawn_enemy_pack(kind, pack_size)
		spawn_events += 1

	var enemy_counts := {}
	for enemy in enemies:
		var type := str(enemy.get("type", "unknown"))
		enemy_counts[type] = int(enemy_counts.get(type, 0)) + 1

	print("DEBUG_SPIDER_RELIC_WAVE2 relic_count=%d cap=%d spawn_events=%d event_counts=%s enemy_counts=%s spider_packs=%d report=\"%s\"" % [
		_relic_count("overheated_footsteps"),
		_enemy_cap(),
		spawn_events,
		str(event_counts),
		str(enemy_counts),
		spider_relic_packs_this_wave,
		_run_report_console_summary(),
	])
	get_tree().quit()


func _capture_ui_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("/private/tmp/orebound-godot-ui.png")
	get_tree().quit()


func _capture_choice_ui_and_quit() -> void:
	_reset_run(true)
	if not smoke_weapon_id.is_empty():
		_equip_weapon_for_run(smoke_weapon_id)
	level = 2
	var capture_rewards: Array = []
	for reward in _stat_rewards_for_selected_weapon():
		if ["damage", "cooldown", "range"].has(str(reward.get("id", ""))):
			capture_rewards.append(reward)
	mode = MODE_CHOICE
	_show_choice_overlay("레벨 %d" % level, "보상 선택", capture_rewards, "_choose_reward")
	for frame in range(6):
		await get_tree().process_frame
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(CHOICE_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_shop_ui_and_quit() -> void:
	_reset_run(true)
	_equip_weapon_for_run("pickaxe")
	wave = 3
	rounds_cleared = 2
	_set_currency_ledger_for_debug("ore", 120, 120, 0)
	_set_currency_ledger_for_debug("catalyst", 7, 9, 2)
	_set_currency_ledger_for_debug("forge_core", 3, 4, 1)
	_add_relic(_relic_by_id("chosen_prey"))
	_add_relic(_relic_by_id("overheated_footsteps"))
	_add_relic(_relic_by_id("overheated_footsteps"))
	_open_shop()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(SHOP_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_relic_ui_and_quit() -> void:
	_reset_run(true)
	wave = 2
	rounds_cleared = 1
	_set_round_currency_amount("ore", 34)
	_set_currency_ledger_for_debug("ore", 62, 62, 0)
	_add_relic(_relic_by_id("rough_vein"))
	_open_relic_choice()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(RELIC_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_run_report_ui_and_quit() -> void:
	_reset_run(true)
	_equip_weapon_for_run("lantern")
	_current_upgrade_target()["upgrade_rank"] = 2
	_hide_overlay()
	mode = MODE_VICTORY
	wave = MAX_ROUNDS
	rounds_cleared = MAX_ROUNDS
	level = 5
	elapsed = 78.4
	_set_currency_ledger_for_debug("ore", 44, 166, 122)
	_set_currency_ledger_for_debug("catalyst", 6, 12, 6)
	_set_currency_ledger_for_debug("forge_core", 1, 4, 3)
	run_round_clear_ore = 12
	run_rerolls = 3
	run_kill_count = 93
	run_kills_by_type = {
		"zombie": 31,
		"fast_zombie": 18,
		"spider": 34,
		"thrower": 9,
		"boss": 1,
	}
	run_boss_damage = 420.0
	run_boss_defeated = true
	_add_relic(_relic_by_id("overheated_footsteps"))
	_add_relic(_relic_by_id("overheated_footsteps"))
	_add_relic(_relic_by_id("chosen_prey"))
	_record_shop_purchase({"name": "관통 드릴촉"})
	_record_shop_purchase({"name": "파편 폭약"})
	_record_shop_purchase({"name": "파편 폭약"})
	_record_shop_purchase({"name": "균열 탄심"})
	_show_victory_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(RUN_REPORT_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_combat_feedback_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	wave = MAX_ROUNDS
	elapsed = 14.2
	player["pos"] = Vector2(360.0, 360.0)
	player["moving"] = false
	player["facing_right"] = true
	enemies.clear()
	bullets.clear()
	pickups.clear()
	sparks.clear()
	floating_text.clear()
	_set_currency_ledger_for_debug("ore", 18, 30, 12)
	_set_currency_ledger_for_debug("catalyst", 5, 7, 2)
	_set_currency_ledger_for_debug("forge_core", 2, 3, 1)
	_add_relic(_relic_by_id("chosen_prey"))
	_add_relic(_relic_by_id("cracked_shield_oath"))

	var weapon: Dictionary = weapons[0]
	weapon["mods"] = ["급속 방아쇠", "관통 드릴촉", "파편 폭약", "균열 탄심"]
	weapon["cooldown"] = 0.38
	weapon["damage"] = 19.0
	weapon["range"] = 560.0
	weapon["speed"] = 760.0
	weapon["pierce"] = 2
	weapon["splash"] = 58.0
	weapon["armor_pierce"] = 3.0

	var boss := _make_enemy("boss")
	boss["pos"] = Vector2(760.0, 360.0)
	enemies.append(boss)
	var elite := _make_enemy("elite_zombie")
	elite["pos"] = Vector2(830.0, 430.0)
	enemies.append(elite)
	var spider_positions := [
		Vector2(650.0, 310.0),
		Vector2(690.0, 330.0),
		Vector2(716.0, 405.0),
		Vector2(672.0, 430.0),
		Vector2(622.0, 405.0),
	]
	for pos in spider_positions:
		var spider := _make_enemy("spider")
		spider["pos"] = pos
		enemies.append(spider)
	pickups.append({"pos": Vector2(486.0, 500.0), "radius": 8.0, "type": "xp", "value": 6.0, "color": Color("#6cc3c0")})
	pickups.append({"pos": Vector2(520.0, 500.0), "radius": 6.0, "type": "currency", "currency_id": "ore", "shape": "diamond", "value": 1, "color": Color("#e6b85c")})
	pickups.append({"pos": Vector2(548.0, 500.0), "radius": 6.0, "type": "currency", "currency_id": "catalyst", "shape": "ring", "value": 1, "color": Color("#6cc3c0")})
	pickups.append({"pos": Vector2(576.0, 500.0), "radius": 7.0, "type": "currency", "currency_id": "forge_core", "shape": "hex", "value": 1, "color": Color("#f0643b")})

	_fire_projectiles(weapon, boss, 620.0, false)
	for frame in range(34):
		_update_bullets(1.0 / 60.0)
		_update_sparks(1.0 / 60.0)
		_update_floating_text(1.0 / 60.0)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(COMBAT_FEEDBACK_CAPTURE_PATH)
	get_tree().quit()


func _capture_p6_map_camera_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	wave = 4
	elapsed = 18.6
	player["pos"] = Vector2(1684.0, 1536.0)
	player["moving"] = true
	player["facing_right"] = true
	camera_pos = _clamped_camera_position(player["pos"])
	enemies.clear()
	spawn_warnings.clear()
	var positions := [
		Vector2(1420, 1408),
		Vector2(1768, 1336),
		Vector2(1900, 1640),
		Vector2(1510, 1752),
	]
	var types := ["zombie", "fast_zombie", "thrower", "spider"]
	for i in range(positions.size()):
		var enemy := _make_enemy(types[i])
		enemy["pos"] = positions[i]
		enemies.append(enemy)
	_queue_spawn_warning("spider", 5)
	_queue_spawn_warning("elite_zombie", 1)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P6_MAP_CAMERA_CAPTURE_PATH)
	get_tree().quit()


func _capture_spawn_telegraph_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	wave = 3
	elapsed = 9.5
	player["pos"] = WORLD_SIZE * 0.5
	camera_pos = _clamped_camera_position(player["pos"])
	enemies.clear()
	spawn_warnings.clear()
	var center := _visible_world_rect().position + VIEW_SIZE * 0.5
	spawn_warnings.append({"kind": "zombie", "pack_size": 1, "pos": center + Vector2(-260, -80), "timer": 0.62, "duration": SPAWN_WARNING_DURATION, "seed": 13.0})
	spawn_warnings.append({"kind": "spider", "pack_size": 5, "pos": center + Vector2(70, 118), "timer": 0.34, "duration": SPAWN_WARNING_DURATION, "seed": 77.0})
	spawn_warnings.append({"kind": "elite_zombie", "pack_size": 1, "pos": center + Vector2(312, -18), "timer": 0.14, "duration": SPAWN_WARNING_DURATION, "seed": 151.0})
	var emerging := _make_enemy("fast_zombie")
	emerging["pos"] = center + Vector2(-48, -174)
	emerging["emerge_timer"] = ENEMY_EMERGE_DURATION * 0.58
	enemies.append(emerging)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(SPAWN_TELEGRAPH_CAPTURE_PATH)
	get_tree().quit()


func _capture_pause_ui_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	wave = 4
	wave_timer = 28.0
	_set_currency_ledger_for_debug("ore", 86, 86, 0)
	run_kill_count = 42
	run_purchase_count = 3
	run_rerolls = 1
	_add_relic(_relic_by_id("overheated_footsteps"))
	_add_relic(_relic_by_id("chosen_prey"))
	var weapon: Dictionary = weapons[0]
	weapon["mods"] = ["급속 방아쇠", "관통 드릴촉", "파편 폭약"]
	weapon["damage"] = 19.0
	weapon["cooldown"] = 0.42
	weapon["pierce"] = 1
	weapon["splash"] = 42.0
	_render_weapons()
	_set_paused(true)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(PAUSE_UI_CAPTURE_PATH)
	get_tree().quit()


func _debug_boss_pierce_splash_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	wave = MAX_ROUNDS
	debug_hurt_events = 0
	var failures := 0
	var results := PackedStringArray()
	var first_probe := ""
	for step in range(8):
		enemies.clear()
		bullets.clear()
		var boss: Dictionary = _make_enemy("boss")
		boss["pos"] = WORLD_SIZE * 0.5
		enemies.append(boss)

		var angle: float = TAU * float(step) / 8.0
		var direction := Vector2.RIGHT.rotated(angle)
		var boss_pos: Vector2 = boss["pos"]
		var start_hp := float(enemies[0]["hp"])
		player["pos"] = boss_pos - direction * 240.0
		var weapon := {
			"id": "drill_tip",
			"speed": 690.0,
			"projectiles": 1,
			"spread": 0.0,
			"damage": 16.0,
			"color": Color("#d8ceb9"),
			"pierce": 1,
			"splash": 42.0,
			"armor_pierce": 0.0,
			"knockback": 0.0,
			"shape": "drill_tip",
		}
		_fire_projectiles(weapon, boss, 430.0, false)
		var min_distance := 9999.0
		var collision_radius: float = 47.0
		for frame in range(40):
			if bullets.is_empty():
				break
			for bullet in bullets:
				min_distance = min(min_distance, Vector2(bullet["pos"]).distance_to(boss_pos))
			_update_bullets(1.0 / 60.0)

		var boss_after: Dictionary = enemies[0]
		var damage: float = start_hp - float(boss_after["hp"])
		if step == 0:
			first_probe = "player=%s boss=%s min_distance=%.2f collision_radius=%.2f bullets_left=%d hurt_events=%d" % [
				str(player["pos"]),
				str(boss_pos),
				min_distance,
				collision_radius,
				bullets.size(),
				debug_hurt_events,
			]
		if damage <= 0.0:
			failures += 1
		results.append("%ddeg=%.1f" % [int(round(rad_to_deg(angle))), damage])

	print("DEBUG_BOSS_PIERCE_SPLASH failures=%d probe={%s} results=%s report=\"%s\"" % [failures, first_probe, ", ".join(results), _run_report_console_summary()])
	get_tree().quit(1 if failures > 0 else 0)


func _debug_emerging_death_cleanup_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	wave = 3
	enemies.clear()
	sparks.clear()
	_add_relic(_relic_by_id("shortened_fuse"))
	for i in range(5):
		var spider := _make_enemy("spider")
		spider["pos"] = player["pos"] + Vector2.RIGHT.rotated(TAU * float(i) / 5.0) * 50.0
		spider["hp"] = 0.0
		spider["emerge_timer"] = ENEMY_EMERGE_DURATION
		enemies.append(spider)

	_update_enemies(1.0 / 60.0)
	var dead_emerging_left := 0
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 and _enemy_is_emerging(enemy):
			dead_emerging_left += 1

	for frame in range(80):
		_update_sparks(1.0 / 60.0)
	var lingering_ring_count := 0
	for spark in sparks:
		if bool(spark.get("ring", false)):
			lingering_ring_count += 1

	print("DEBUG_EMERGING_DEATH_CLEANUP dead_emerging_left=%d enemies=%d sparks=%d lingering_rings=%d" % [
		dead_emerging_left,
		enemies.size(),
		sparks.size(),
		lingering_ring_count,
	])
	get_tree().quit(1 if dead_emerging_left > 0 else 0)


func _capture_stage1_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	wave = 1
	wave_timer = P1_ROUND_DURATION
	elapsed = 2.4
	enemies.clear()
	var offsets := [
		Vector2(-220, -120),
		Vector2(-170, 80),
		Vector2(-70, -185),
		Vector2(130, -150),
		Vector2(210, -20),
		Vector2(90, 125),
		Vector2(-250, 150),
	]
	for offset in offsets:
		var enemy := _make_enemy("zombie")
		enemy["pos"] = player["pos"] + offset
		enemies.append(enemy)
	player["moving"] = true
	player["facing_right"] = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(STAGE1_CAPTURE_PATH)
	get_tree().quit()


func _capture_monster_roster_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = "capture"
	wave = 5
	wave_timer = P1_BOSS_ROUND_DURATION
	elapsed = 3.1
	enemies.clear()
	var roster := [
		{"type": "zombie", "offset": Vector2(-330, -90)},
		{"type": "fast_zombie", "offset": Vector2(-190, -90)},
		{"type": "spider", "offset": Vector2(-55, -90)},
		{"type": "thrower", "offset": Vector2(100, -90)},
		{"type": "shield_zombie", "offset": Vector2(250, -86)},
		{"type": "boss", "offset": Vector2(430, -65)},
	]
	for item in roster:
		var enemy := _make_enemy(item["type"])
		enemy["pos"] = player["pos"] + item["offset"]
		enemies.append(enemy)
	player["moving"] = false
	player["facing_right"] = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(MONSTER_ROSTER_CAPTURE_PATH)
	get_tree().quit()


func _capture_p7_shop_rarity_ui_and_quit() -> void:
	_reset_run(true)
	wave = 8
	rounds_cleared = 7
	_set_currency_ledger_for_debug("ore", 180, 180, 0)
	shop_stock = [
		_shop_item_by_id("lubricated_bearing").duplicate(true),
		_shop_item_by_id("piercing_bit").duplicate(true),
		_shop_item_by_id("double_drill_chamber").duplicate(true),
		_shop_item_by_id("recoil_spring").duplicate(true),
	]
	for i in range(shop_stock.size()):
		shop_stock[i]["stock_id"] = "capture_%d" % i
		shop_stock[i]["cost"] = _typed_cost("ore", _scaled_shop_cost(int(shop_stock[i]["cost"]), str(shop_stock[i].get("rarity", "common"))))
	active_reward_context = {"type": "shop"}
	pending_reward_chain.clear()
	_show_shop_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P7_SHOP_RARITY_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_p7_contract_ui_and_quit() -> void:
	_reset_run(true)
	wave = 5
	rounds_cleared = 5
	_set_round_currency_amount("ore", 68)
	_set_currency_ledger_for_debug("ore", 116, 116, 0)
	_add_relic(_relic_by_id("overheated_footsteps"))
	_open_contract_choice()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P7_CONTRACT_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_p7_boss_patterns_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	wave = 10
	player["pos"] = WORLD_SIZE * 0.5 + Vector2(-180, 0)
	camera_pos = _clamped_camera_position(player["pos"])
	enemies.clear()
	var boss := _make_enemy("final_boss")
	boss["pos"] = player["pos"] + Vector2(270, 0)
	boss["charge_state"] = "windup"
	boss["charge_timer"] = 0.48
	boss["charge_dir"] = (player["pos"] - boss["pos"]).normalized()
	enemies.append(boss)
	_spawn_poison_zone(boss["pos"] + Vector2(-60, 86), 92.0, 3.5, 4.0, Color("#7560a8"))
	_boss_barrage(boss)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P7_BOSS_PATTERNS_CAPTURE_PATH)
	get_tree().quit()


func _capture_p7_game_over_summary_and_quit() -> void:
	_reset_run(true)
	_equip_weapon_for_run("pickaxe")
	_hide_overlay()
	mode = MODE_GAME_OVER
	wave = 7
	rounds_cleared = 6
	elapsed = 154.0
	_set_currency_ledger_for_debug("ore", 23, 214, 191)
	_set_currency_ledger_for_debug("catalyst", 2, 8, 6)
	_set_currency_ledger_for_debug("forge_core", 1, 2, 1)
	run_round_clear_ore = 12
	run_rerolls = 4
	run_kill_count = 148
	run_kills_by_type = {"zombie": 44, "fast_zombie": 29, "spider": 38, "thrower": 17, "shield_zombie": 8, "toxic_spider": 12}
	_add_relic(_relic_by_id("overheated_footsteps"))
	_add_relic(_relic_by_id("overheated_footsteps"))
	_add_relic(_relic_by_id("cracked_shield_oath"))
	_record_shop_purchase(_shop_item_by_id("piercing_bit"))
	_record_shop_purchase(_shop_item_by_id("double_drill_chamber"))
	_show_game_over_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P7_GAME_OVER_SUMMARY_CAPTURE_PATH)
	get_tree().quit()


func _capture_p8_weapon_select_ui_and_quit() -> void:
	_reset_run(false)
	_open_weapon_select()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P8_WEAPON_SELECT_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_p8_shop_weapon_parts_and_quit() -> void:
	_reset_run(false)
	_equip_weapon_for_run("lantern")
	mode = MODE_CHOICE
	wave = 8
	rounds_cleared = 7
	_set_round_currency_amount("ore", 92)
	_set_currency_ledger_for_debug("ore", 190, 190, 0)
	shop_stock = [
		_shop_item_by_id("lubricated_bearing").duplicate(true),
		_shop_item_by_id("extended_shaft").duplicate(true),
		_shop_item_by_id("piercing_bit").duplicate(true),
		_shop_item_by_id("double_drill_chamber").duplicate(true),
	]
	for i in range(shop_stock.size()):
		shop_stock[i]["stock_id"] = "p8_capture_%d" % i
		shop_stock[i]["cost"] = _typed_cost("ore", _scaled_shop_cost(int(shop_stock[i]["cost"]), str(shop_stock[i].get("rarity", "common"))))
	active_reward_context = {"type": "shop"}
	pending_reward_chain.clear()
	_show_shop_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P8_SHOP_WEAPON_PARTS_CAPTURE_PATH)
	get_tree().quit()


func _capture_p8_pickaxe_swing_and_quit() -> void:
	_reset_run(false)
	_equip_weapon_for_run("pickaxe")
	_hide_overlay()
	mode = MODE_PLAY
	wave = 1
	player["pos"] = WORLD_SIZE * 0.5
	player["moving"] = false
	player["facing_right"] = true
	camera_pos = _clamped_camera_position(player["pos"])
	enemies.clear()
	sparks.clear()
	floating_text.clear()
	var front := _make_enemy("zombie")
	front["pos"] = player["pos"] + Vector2(96.0, 0.0)
	enemies.append(front)
	var side := _make_enemy("spider")
	side["pos"] = player["pos"] + Vector2(116.0, 48.0)
	enemies.append(side)
	_fire_weapon(weapons[0], front, float(weapons[0]["range"]))
	for frame in range(2):
		_update_sparks(1.0 / 60.0)
		_update_floating_text(1.0 / 60.0)
	mode = "capture"
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(P8_PICKAXE_SWING_CAPTURE_PATH)
	get_tree().quit()


func _capture_checkpoint_ui_and_quit() -> void:
	_reset_run(true)
	var risk_open := RunRulesScript.open_checkpoint(run_rule_state, 3)
	var risk_result: Dictionary = RunRulesScript.select_checkpoint_route(risk_open, "risk")
	var risk_state: Dictionary = RunRulesScript.attach_persistent_risk(risk_result.get("state", risk_open), "rough_vein")
	var elite_open := RunRulesScript.open_checkpoint(risk_state, 5)
	var elite_result: Dictionary = RunRulesScript.select_checkpoint_route(elite_open, "elite")
	_set_run_rule_state(elite_result.get("state", elite_open))
	_add_relic(_relic_by_id("rough_vein"))
	wave = 6
	mode = MODE_PLAY
	_hide_overlay()
	_update_hud()
	queue_redraw()
	for frame in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var hud_image := get_viewport().get_texture().get_image()
	hud_image.save_png(CHECKPOINT_HUD_CAPTURE_PATH)

	wave = 5
	rounds_cleared = 5
	_set_round_currency_amount("ore", 52)
	_set_currency_ledger_for_debug("ore", 96, 96, 0)
	player["hp"] = 42.0
	_set_run_rule_state(RunRulesScript.open_checkpoint(risk_state, wave))
	_open_checkpoint_choice()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(CHECKPOINT_UI_CAPTURE_PATH)
	print("CHECKPOINT_CAPTURE overlay=%s hud=%s size=%s" % [CHECKPOINT_UI_CAPTURE_PATH, CHECKPOINT_HUD_CAPTURE_PATH, str(image.get_size())])
	get_tree().quit()


func _smoke_checkpoint_route_and_quit(route_id: String) -> void:
	_reset_run(true)
	_hide_overlay()
	wave = 3
	rounds_cleared = 3
	player["hp"] = 37.0
	var hp_before := float(player["hp"])
	_set_run_rule_state(RunRulesScript.open_checkpoint(run_rule_state, wave))
	_open_checkpoint_choice()
	if route_id.is_empty():
		_choose_checkpoint_route({})
		_checkpoint_smoke_fail("missing_route", route_id)
		return
	if route_id == "disabled":
		var disabled_option := _active_choice_option_by_id("safe").duplicate(true)
		disabled_option["disabled"] = true
		active_choice_options[0] = disabled_option
		_choose_checkpoint_route(disabled_option)
		_checkpoint_smoke_fail("disabled_route", route_id)
		return
	if route_id == "unchanged":
		var safe_option := _active_choice_option_by_id("safe")
		_choose_checkpoint_route(safe_option)
		var repeated: Dictionary = RunRulesScript.select_checkpoint_route(run_rule_state, "safe")
		if str(repeated.get("error", "")) == "checkpoint_already_selected":
			_checkpoint_smoke_fail("unchanged_route", route_id)
		else:
			_checkpoint_smoke_fail("immutability_not_enforced", route_id)
		return
	if not RunRulesScript.is_checkpoint_route(route_id):
		_choose_checkpoint_route({"id": route_id, "kind": "checkpoint_route"})
		_checkpoint_smoke_fail("unknown_route", route_id)
		return
	var option := _active_choice_option_by_id(route_id)
	if option.is_empty() or _choice_option_disabled(option):
		_checkpoint_smoke_fail("route_unavailable", route_id)
		return
	_choose_checkpoint_route(option)
	if route_id == "risk":
		if active_choice_method != "_choose_checkpoint_risk_relic" or active_choice_options.is_empty():
			_checkpoint_smoke_fail("risk_contract_missing", route_id)
			return
		_choose_checkpoint_risk_relic(active_choice_options[0])
	elif route_id == "shop":
		var exit_option := _active_choice_option_by_id("next_round")
		if exit_option.is_empty() or int(_option_cost(exit_option).get("amount", -1)) != 0:
			_checkpoint_smoke_fail("free_shop_exit_missing", route_id)
			return
		_choose_shop_option(exit_option)
	var hp_after := float(player.get("hp", 0.0))
	var expected_hp := float(player.get("max_hp", 0.0)) if route_id == "safe" else hp_before
	var risk_attached := route_id != "risk" or not Array(run_rule_state.get("persistent_risks", [])).is_empty()
	var valid := mode == MODE_PLAY and wave == 4 and is_equal_approx(hp_after, expected_hp) and str(run_rule_state.get("selected_route", "")) == route_id and risk_attached
	print("SMOKE_CHECKPOINT_ROUTE result=%s route=%s mode=%s wave=%d hp_before=%.1f hp_after=%.1f state=%s" % [
		"PASS" if valid else "FAIL", route_id, mode, wave, hp_before, hp_after, JSON.stringify(run_rule_state),
	])
	get_tree().quit(0 if valid else 1)


func _checkpoint_smoke_fail(reason: String, route_id: String) -> void:
	print("SMOKE_CHECKPOINT_ROUTE result=FAIL reason=%s route=%s mode=%s wave=%d state=%s options=%s" % [
		reason, route_id, mode, wave, JSON.stringify(run_rule_state), JSON.stringify(active_choice_options),
	])
	get_tree().quit(1)


func _active_choice_option_by_id(id: String) -> Dictionary:
	for option in active_choice_options:
		if str(option.get("id", "")) == id:
			return option
	return {}


func _debug_p7_reward_routes_and_quit() -> void:
	var failures := 0
	for round_index in range(1, MAX_ROUNDS + 1):
		var actual := _reward_route_label(round_index)
		var expected := ""
		match round_index:
			1:
				expected = "stat"
			2:
				expected = "shop"
			3:
				expected = "checkpoint"
			4:
				expected = "shop"
			5:
				expected = "stat -> checkpoint"
			6:
				expected = "shop"
			7:
				expected = "stat -> checkpoint"
			8:
				expected = "shop"
			9:
				expected = "final_shop"
			10:
				expected = "victory"
		if actual != expected:
			failures += 1
		print("DEBUG_P7_REWARD_ROUTE round=%d duration=%.1f boss=%s route=\"%s\" expected=\"%s\" warning=\"%s\"" % [
			round_index,
			_round_duration(round_index),
			str(_round_is_boss(round_index)),
			actual,
			expected,
			_next_round_warning_text(min(round_index + 1, MAX_ROUNDS)),
		])
	print("DEBUG_P7_REWARD_ROUTES failures=%d" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _debug_p7_shop_rarity_and_quit() -> void:
	_reset_run(true)
	var counts := {"common": 0, "rare": 0, "legendary": 0}
	var min_cost := 999
	var max_cost := 0
	for round_index in range(2, 10):
		wave = round_index - 1
		for i in range(80):
			var stock := _roll_shop_stock([])
			for item in stock:
				var rarity := str(item.get("rarity", "common"))
				counts[rarity] = int(counts.get(rarity, 0)) + 1
				var amount := int(_option_cost(item).get("amount", 0))
				min_cost = min(min_cost, amount)
				max_cost = max(max_cost, amount)
	print("DEBUG_P7_SHOP_RARITY counts=%s min_cost=%d max_cost=%d legendary_expected=\"0-1 per normal run, not guaranteed\"" % [str(counts), min_cost, max_cost])
	get_tree().quit(1 if int(counts.get("common", 0)) <= 0 or int(counts.get("rare", 0)) <= 0 else 0)


func _debug_p7_relic_contracts_and_quit() -> void:
	_reset_run(true)
	var failures := 0
	for round_index in [3, 5, 7]:
		wave = round_index
		var options := _roll_relic_options()
		var names := PackedStringArray()
		for option in options:
			names.append("%s:%s" % [str(option.get("name", "")), _roman_level(_relic_count(str(option.get("id", ""))) + 1)])
			if str(option.get("reward_hint", "")).is_empty():
				failures += 1
		print("DEBUG_P7_CONTRACT_OPTIONS round=%d options=%s" % [round_index, ", ".join(names)])
		if options.is_empty():
			failures += 1
		_add_relic(options[0])
	var catalyst_probe := {"type": "fast_zombie", "currency_drop": DemoContentScript.enemy_currency_profile("fast_zombie"), "elite": true}
	print("DEBUG_P7_RELIC_CONTRACTS failures=%d contracts=\"%s\" rough_hp=%.2f elite_probe=%s currency_mult=%.2f" % [
		failures,
		_format_relic_counts_for_report(),
		_contract_enemy_hp_multiplier("zombie"),
		str(_should_make_contract_elite("zombie")),
		_contract_currency_multiplier(catalyst_probe, "catalyst"),
	])
	get_tree().quit(1 if failures > 0 else 0)


func _debug_p7_boss_patterns_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	var mid := _make_enemy("mid_boss")
	mid["pos"] = WORLD_SIZE * 0.5
	enemies.append(mid)
	_execute_boss_pattern(mid)
	var mid_state := str(mid.get("charge_state", "idle"))
	enemies.clear()
	var final := _make_enemy("final_boss")
	final["pos"] = WORLD_SIZE * 0.5
	final["hp"] = float(final["max_hp"]) * 0.30
	enemies.append(final)
	_execute_boss_pattern(final)
	_execute_boss_pattern(final)
	_execute_boss_pattern(final)
	_execute_boss_pattern(final)
	var has_projectiles := enemy_projectiles.size() > 0
	print("DEBUG_P7_BOSS_PATTERNS mid_state=%s hazards=%d projectiles=%d summons=%d final_phase=%d" % [
		mid_state,
		hazard_zones.size(),
		enemy_projectiles.size(),
		enemies.size() - 1,
		_boss_phase(final),
	])
	get_tree().quit(1 if mid_state != "windup" or not has_projectiles else 0)


func _debug_u3_balance_contract_and_quit() -> void:
	_reset_run(true)
	var failures := 0
	var expected_weapons := {
		"pickaxe": {"cooldown": 1.05, "damage": 35.0, "range": 124.0, "range_token": "휘두름 범위"},
		"nailgun": {"cooldown": 0.62, "damage": 15.0, "range": 360.0, "range_token": "못 비행 거리"},
		"lantern": {"cooldown": 1.35, "damage": 17.0, "range": 158.0, "range_token": "빛 펄스 반경"},
	}
	var reward_summaries := {}
	for weapon_id in ["pickaxe", "nailgun", "lantern"]:
		var expected: Dictionary = expected_weapons[weapon_id]
		var actual: Dictionary = weapon_catalog[weapon_id]
		for key in ["cooldown", "damage", "range"]:
			if not is_equal_approx(float(actual.get(key, 0.0)), float(expected[key])):
				failures += 1
		_equip_weapon_for_run(weapon_id)
		var range_reward := {}
		for reward in _stat_rewards_for_selected_weapon():
			if str(reward.get("id", "")) == "range":
				range_reward = reward
				break
		var reward_text := "%s %s" % [str(range_reward.get("name", "")), str(range_reward.get("desc", ""))]
		reward_summaries[weapon_id] = reward_text
		if not reward_text.contains(str(expected["range_token"])):
			failures += 1
		if weapon_id != "nailgun" and (reward_text.contains("화살촉") or reward_text.contains("드릴촉") or reward_text.contains("투사체")):
			failures += 1

	var mid := _make_enemy("mid_boss")
	var final := _make_enemy("final_boss")
	if not is_equal_approx(float(mid.get("hp", 0.0)), 680.0) or not is_equal_approx(float(mid.get("speed", 0.0)), 70.0):
		failures += 1
	if not is_equal_approx(float(final.get("hp", 0.0)), 1550.0) or not is_equal_approx(float(final.get("speed", 0.0)), 74.0):
		failures += 1

	hazard_zones.clear()
	mid["pattern_index"] = 1
	_execute_boss_pattern(mid)
	var pool_radius := 0.0
	if not hazard_zones.is_empty():
		pool_radius = float(Dictionary(hazard_zones[0]).get("radius", 0.0))
	if not is_equal_approx(pool_radius, BOSS_POOL_RADIUS):
		failures += 1

	print("DEBUG_U3_BALANCE_CONTRACT failures=%d weapons=%s rewards=%s mid_hp=%.1f mid_speed=%.1f final_hp=%.1f final_speed=%.1f pool_radius=%.1f" % [
		failures,
		JSON.stringify(expected_weapons),
		JSON.stringify(reward_summaries),
		float(mid.get("hp", 0.0)),
		float(mid.get("speed", 0.0)),
		float(final.get("hp", 0.0)),
		float(final.get("speed", 0.0)),
		pool_radius,
	])
	get_tree().quit(1 if failures > 0 else 0)


func _debug_p7_elite_marker_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	elapsed = 7.4
	player["pos"] = Vector2(560.0, 360.0)
	camera_pos = _clamped_camera_position(player["pos"])
	enemies.clear()
	var elite := _make_enemy("shield_zombie")
	elite["pos"] = Vector2(740.0, 360.0)
	elite["elite"] = true
	elite["hit_flash"] = 0.0
	enemies.append(elite)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var screen_pos: Vector2 = Vector2(elite["pos"]) - _camera_origin()
	var ring_radius := float(elite["radius"]) + 11.0
	var sample_angles := [0.0, PI * 0.25, PI * 0.75, PI, PI * 1.25, PI * 1.75]
	var body_ring_pixels := 0
	for angle in sample_angles:
		var sample: Vector2 = screen_pos + Vector2.RIGHT.rotated(float(angle)) * ring_radius
		for ox in range(-2, 3):
			for oy in range(-2, 3):
				var pixel_pos := Vector2i(int(round(sample.x)) + ox, int(round(sample.y)) + oy)
				if pixel_pos.x < 0 or pixel_pos.y < 0 or pixel_pos.x >= image.get_width() or pixel_pos.y >= image.get_height():
					continue
				if _is_elite_body_ring_pixel(image.get_pixelv(pixel_pos)):
					body_ring_pixels += 1
	print("DEBUG_P7_ELITE_MARKER body_ring_pixels=%d expected=0" % body_ring_pixels)
	get_tree().quit(1 if body_ring_pixels > 0 else 0)


func _is_elite_body_ring_pixel(color: Color) -> bool:
	return color.a > 0.35 and color.r > 0.72 and color.g > 0.52 and color.g < 0.84 and color.b > 0.20 and color.b < 0.48


func _debug_p7_pause_cycle_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	_set_paused(true)
	await get_tree().process_frame
	var first_pause_visible: bool = paused and game_ui.pause_banner.visible
	var first_pause_centered := _pause_overlay_centered()
	var resume_button := _find_button_by_text(game_ui.pause_box, "계속")
	if resume_button != null:
		resume_button.grab_focus()
		resume_button.emit_signal("pressed")
	else:
		game_ui.resume_requested.emit()
	await get_tree().process_frame
	var resumed: bool = not paused and not game_ui.pause_banner.visible
	var pause_focus_released: bool = get_viewport().gui_get_focus_owner() == null
	var elapsed_before_update := elapsed
	_update_game(0.10)
	var game_advanced_after_resume := elapsed > elapsed_before_update

	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	_input(event)
	await get_tree().process_frame
	var second_pause_visible: bool = paused and game_ui.pause_banner.visible
	var second_pause_centered := _pause_overlay_centered()
	game_ui.hide_pause()
	_process(0.016)
	var hidden_pause_recovers: bool = paused and game_ui.pause_banner.visible
	_input(event)
	var second_resume_visible: bool = not paused and not game_ui.pause_banner.visible

	mode = MODE_PLAY
	wave = 1
	wave_timer = 0.0
	pending_reward_chain.clear()
	_set_paused(true)
	game_ui.hide_pause()
	_finish_round()
	var round_reward_visible: bool = mode == MODE_CHOICE and not paused and game_ui.overlay.visible and not game_ui.pause_banner.visible

	print("DEBUG_P7_PAUSE_CYCLE first=%s first_centered=%s resumed=%s focus_released=%s advanced=%s second_pause=%s second_centered=%s hidden_recovers=%s second_resume=%s round_reward=%s %s" % [
		str(first_pause_visible),
		str(first_pause_centered),
		str(resumed),
		str(pause_focus_released),
		str(game_advanced_after_resume),
		str(second_pause_visible),
		str(second_pause_centered),
		str(hidden_pause_recovers),
		str(second_resume_visible),
		str(round_reward_visible),
		_pause_overlay_rect_debug(),
	])
	get_tree().quit(1 if not first_pause_visible or not first_pause_centered or not resumed or not pause_focus_released or not game_advanced_after_resume or not second_pause_visible or not second_pause_centered or not hidden_pause_recovers or not second_resume_visible or not round_reward_visible else 0)


func _find_button_by_text(root_node: Node, text: String) -> Button:
	if root_node is Button and str(root_node.text) == text:
		return root_node
	for child in root_node.get_children():
		var found := _find_button_by_text(child, text)
		if found != null:
			return found
	return null


func _pause_overlay_centered() -> bool:
	if game_ui == null or game_ui.pause_box == null:
		return false
	var rect: Rect2 = game_ui.pause_box.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	var center: Vector2 = rect.get_center()
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	var expected := viewport_size * 0.5
	return absf(center.x - expected.x) <= 80.0 and absf(center.y - expected.y) <= 80.0


func _pause_overlay_rect_debug() -> String:
	if game_ui == null or game_ui.pause_box == null:
		return "missing"
	var rect: Rect2 = game_ui.pause_box.get_global_rect()
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	return "rect_pos=%s rect_size=%s center=%s expected=%s" % [
		str(rect.position),
		str(rect.size),
		str(rect.get_center()),
		str(viewport_size * 0.5),
	]


func _debug_p7_legendary_aim_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_PLAY
	player["pos"] = Vector2(640.0, 640.0)
	enemies.clear()
	bullets.clear()
	var target := _make_enemy("spider")
	target["pos"] = Vector2(900.0, 640.0)
	enemies.append(target)

	var item := _shop_item_by_id("double_drill_chamber")
	_apply_weapon_part_stats(item.get("weapon_stats", {}), str(item.get("name", "")))
	var weapon: Dictionary = weapons[0]
	_fire_projectiles(weapon, target, 520.0, false)

	var centerline_count := 0
	var angle_text := PackedStringArray()
	for bullet in bullets:
		var velocity: Vector2 = bullet.get("velocity", Vector2.ZERO)
		if velocity.length_squared() <= 0.0:
			continue
		var direction := velocity.normalized()
		angle_text.append("%.3f" % rad_to_deg(direction.angle()))
		if absf(direction.angle_to(Vector2.RIGHT)) <= 0.001:
			centerline_count += 1
	print("DEBUG_P7_LEGENDARY_AIM bullets=%d centerline=%d angles=%s" % [
		bullets.size(),
		centerline_count,
		", ".join(angle_text),
	])
	get_tree().quit(1 if bullets.size() < 2 or centerline_count <= 0 else 0)


func _debug_p8_weapon_routes_and_quit() -> void:
	var failures := 0
	var route_results := PackedStringArray()

	_reset_run(false)
	_open_weapon_select()
	var timer_before := wave_timer
	var spawn_before := spawn_timer
	_process(0.50)
	var select_frozen := mode == MODE_CHOICE and weapons.is_empty() and enemies.is_empty() and bullets.is_empty() and absf(wave_timer - timer_before) <= 0.001 and absf(spawn_timer - spawn_before) <= 0.001
	if not select_frozen:
		failures += 1

	for id in starter_weapon_ids:
		_reset_run(false)
		var option := {"id": id, "kind": "starter_weapon"}
		_choose_starter_weapon(option)
		var equipped: bool = weapons.size() == 1 and str(Dictionary(weapons[0]).get("id", "")) == id and selected_weapon_id == id and mode == MODE_PLAY
		var attack_ok: bool = _debug_p8_probe_weapon_attack(id)
		var shop_ok: bool = _debug_p8_probe_shop_decoration(id)
		var legendary_ok: bool = _debug_p8_probe_legendary_interpretation(id)
		if not equipped or not attack_ok or not shop_ok or not legendary_ok:
			failures += 1
		route_results.append("%s equipped=%s attack=%s shop=%s legendary=%s" % [id, str(equipped), str(attack_ok), str(shop_ok), str(legendary_ok)])

	print("DEBUG_P8_WEAPON_ROUTES select_frozen=%s failures=%d routes=%s" % [
		str(select_frozen),
		failures,
		" | ".join(route_results),
	])
	get_tree().quit(1 if failures > 0 else 0)


func _debug_demo_rule_seams_and_quit() -> void:
	var failures := 0
	run_rule_state["checkpoint_round"] = 7
	run_rule_state["selected_route"] = "risk"
	_reset_run(false)
	var expected_state := RunRulesScript.fresh_run_state()
	if run_rule_state != expected_state:
		failures += 1
	if _reward_route_label(3) != "checkpoint":
		failures += 1
	if _round_duration(5) != P1_BOSS_ROUND_DURATION:
		failures += 1
	if starter_weapon_ids != ["pickaxe", "nailgun", "lantern"]:
		failures += 1
	print("DEBUG_DEMO_RULE_SEAMS failures=%d reset_state=%s reward_r3=\"%s\" starters=%s" % [
		failures,
		str(run_rule_state),
		_reward_route_label(3),
		str(starter_weapon_ids),
	])
	get_tree().quit(1 if failures > 0 else 0)


func _debug_u3_checkpoint_contract_and_quit() -> void:
	_reset_run(true)
	var failures := 0
	wave = 3
	player["hp"] = 31.0
	_set_run_rule_state(RunRulesScript.open_checkpoint(run_rule_state, wave))
	_open_checkpoint_choice()
	_choose_checkpoint_route(_active_choice_option_by_id("safe"))
	var locked_route_before := str(run_rule_state.get("selected_route", ""))
	var wave_before_reopen := wave
	_open_checkpoint_choice()
	var reopen_nonblocking: bool = mode == MODE_PLAY and not game_ui.overlay.visible and wave == wave_before_reopen and str(run_rule_state.get("selected_route", "")) == locked_route_before
	if not reopen_nonblocking:
		failures += 1
	_set_paused(true)
	_open_checkpoint_choice()
	var paused_reopen_immutable: bool = mode == MODE_PLAY and paused and game_ui.pause_banner.visible and not game_ui.overlay.visible and str(run_rule_state.get("selected_route", "")) == locked_route_before
	_set_paused(false)
	var resumed_reopen_immutable: bool = mode == MODE_PLAY and not paused and not game_ui.pause_banner.visible and str(run_rule_state.get("selected_route", "")) == locked_route_before
	if not paused_reopen_immutable or not resumed_reopen_immutable:
		failures += 1
	_reset_run(true)
	wave = 3
	var current_open := RunRulesScript.open_checkpoint(run_rule_state, wave)
	var current_selected: Dictionary = RunRulesScript.select_checkpoint_route(current_open, "safe")
	_set_run_rule_state(current_selected.get("state", current_open))
	mode = MODE_CHOICE
	_open_checkpoint_choice()
	var current_reopen_nonblocking: bool = mode == MODE_PLAY and not game_ui.overlay.visible and wave == 4 and str(run_rule_state.get("selected_route", "")) == "safe"
	if not current_reopen_nonblocking:
		failures += 1
	_reset_run(true)
	var round_3_open := RunRulesScript.open_checkpoint(run_rule_state, 3)
	var round_3_selected: Dictionary = RunRulesScript.select_checkpoint_route(round_3_open, "risk")
	_set_run_rule_state(RunRulesScript.attach_persistent_risk(round_3_selected.get("state", round_3_open), "rough_vein"))
	wave = 5
	mode = MODE_CHOICE
	_open_checkpoint_choice()
	var later_checkpoint_opens: bool = mode == MODE_CHOICE and game_ui.overlay.visible and int(run_rule_state.get("checkpoint_round", 0)) == 5 and str(run_rule_state.get("selected_route", "")).is_empty() and active_choice_method == "_choose_checkpoint_route" and active_choice_options.size() == 4
	if not later_checkpoint_opens:
		failures += 1
	_reset_run(true)
	var state := RunRulesScript.open_checkpoint(run_rule_state, 3)
	var risk_result: Dictionary = RunRulesScript.select_checkpoint_route(state, "risk")
	state = RunRulesScript.attach_persistent_risk(risk_result.get("state", state), "rough_vein")
	state = RunRulesScript.open_checkpoint(state, 5)
	var safe_result: Dictionary = RunRulesScript.select_checkpoint_route(state, "safe")
	state = safe_result.get("state", state)
	var risk_survived := Array(state.get("persistent_risks", [])).size() == 1
	_set_run_rule_state(state)
	var risk_feedback := "\n".join(_checkpoint_feedback_lines()).contains("런 지속")
	if not risk_survived or not risk_feedback:
		failures += 1
	var elite_base := RunRulesScript.open_checkpoint(RunRulesScript.fresh_run_state(), 5)
	var elite_result: Dictionary = RunRulesScript.select_checkpoint_route(elite_base, "elite")
	_set_run_rule_state(RunRulesScript.mark_elite_spawned(elite_result.get("state", elite_base)))
	var core_before := _currency_balance("forge_core")
	_record_enemy_defeat({"type": "elite_zombie", "checkpoint_elite": true, "pos": player.get("pos", Vector2.ZERO)})
	var elite_success := str(Dictionary(run_rule_state.get("elite_segment", {})).get("status", "")) == "success" and _currency_balance("forge_core") == core_before + CHECKPOINT_ELITE_CORE_BONUS
	var success_feedback := "\n".join(_checkpoint_feedback_lines()).contains("성공") and _elite_result_history_text().contains("성공")
	if not elite_success or not success_feedback:
		failures += 1
	var missed_base := RunRulesScript.open_checkpoint(RunRulesScript.fresh_run_state(), 7)
	var missed_result: Dictionary = RunRulesScript.select_checkpoint_route(missed_base, "elite")
	var missed_state: Dictionary = RunRulesScript.advance_checkpoint_state(missed_result.get("state", missed_base), 11)
	var elite_missed := str(Dictionary(missed_state.get("elite_segment", {})).get("status", "")) == "missed"
	_set_run_rule_state(missed_state)
	var missed_feedback := "\n".join(_checkpoint_feedback_lines()).contains("놓침") and _elite_result_history_text().contains("놓침")
	if not elite_missed or not missed_feedback:
		failures += 1
	var route_contract := _reward_route_label(3) == "checkpoint" and _reward_route_label(5) == "stat -> checkpoint" and _reward_route_label(7) == "stat -> checkpoint"
	if not route_contract:
		failures += 1
	print("DEBUG_U3_CHECKPOINT_CONTRACT failures=%d reopen_nonblocking=%s current_reopen_nonblocking=%s later_checkpoint_opens=%s paused_reopen_immutable=%s resumed_reopen_immutable=%s routes=%s risk_survived=%s risk_feedback=%s elite_success=%s success_feedback=%s elite_missed=%s missed_feedback=%s state=%s" % [
		failures, str(reopen_nonblocking), str(current_reopen_nonblocking), str(later_checkpoint_opens), str(paused_reopen_immutable), str(resumed_reopen_immutable), str([_reward_route_label(3), _reward_route_label(5), _reward_route_label(7)]), str(risk_survived), str(risk_feedback), str(elite_success), str(success_feedback), str(elite_missed), str(missed_feedback), JSON.stringify(run_rule_state),
	])
	get_tree().quit(1 if failures > 0 else 0)


func _debug_p8_probe_weapon_attack(id: String) -> bool:
	mode = MODE_PLAY
	wave = 1
	player["pos"] = WORLD_SIZE * 0.5
	enemies.clear()
	bullets.clear()
	hazard_zones.clear()
	sparks.clear()
	debug_hurt_events = 0
	if not _equip_weapon_for_run(id):
		return false
	var weapon: Dictionary = weapons[0]
	match id:
		"pickaxe":
			var front := _make_enemy("zombie")
			front["pos"] = player["pos"] + Vector2(92.0, 0.0)
			var behind := _make_enemy("zombie")
			behind["pos"] = player["pos"] + Vector2(-76.0, 0.0)
			enemies.append(front)
			enemies.append(behind)
			var front_hp := float(front["hp"])
			var behind_hp := float(behind["hp"])
			_fire_weapon(weapon, front, float(weapon["range"]))
			return float(front["hp"]) < front_hp and absf(float(behind["hp"]) - behind_hp) <= 0.001 and bullets.is_empty()
		"nailgun":
			var target := _make_enemy("fast_zombie")
			target["pos"] = player["pos"] + Vector2(260.0, 0.0)
			enemies.append(target)
			var hp_before := float(target["hp"])
			_fire_weapon(weapon, target, float(weapon["range"]))
			var nail_shape := not bullets.is_empty() and str(Dictionary(bullets[0]).get("shape", "")) == "nail"
			for frame in range(38):
				_update_bullets(1.0 / 60.0)
			return nail_shape and float(target["hp"]) < hp_before
		"lantern":
			var near := _make_enemy("spider")
			near["pos"] = player["pos"] + Vector2(72.0, 0.0)
			var far := _make_enemy("thrower")
			far["pos"] = player["pos"] + Vector2(260.0, 0.0)
			enemies.append(near)
			enemies.append(far)
			var near_hp := float(near["hp"])
			var far_hp := float(far["hp"])
			var hazard_count := hazard_zones.size()
			_fire_weapon(weapon, near, float(weapon["range"]))
			return float(near["hp"]) < near_hp and absf(float(far["hp"]) - far_hp) <= 0.001 and hazard_zones.size() == hazard_count
	return false


func _debug_p8_probe_shop_decoration(id: String) -> bool:
	if not _equip_weapon_for_run(id):
		return false
	var piercing := _decorate_shop_option_for_selected_weapon(_shop_item_by_id("piercing_bit"))
	var double := _decorate_shop_option_for_selected_weapon(_shop_item_by_id("double_drill_chamber"))
	var original := _shop_item_by_id("piercing_bit")
	var names_changed := str(piercing.get("name", "")) != str(original.get("name", ""))
	var icon_reused := str(piercing.get("icon", "")) == _current_weapon_icon()
	var double_named := not str(double.get("name", "")).contains("드릴")
	var catalog_preserved := str(original.get("name", "")) == "관통 드릴촉"
	var public_item := _decorate_shop_option_for_selected_weapon(_shop_item_by_id("lightweight_grip"))
	var public_item_preserved := str(public_item.get("name", "")) == "경량 손잡이"
	return names_changed and icon_reused and double_named and catalog_preserved and public_item_preserved


func _debug_p8_probe_legendary_interpretation(id: String) -> bool:
	if not _equip_weapon_for_run(id):
		return false
	var item := _decorate_shop_option_for_selected_weapon(_shop_item_by_id("double_drill_chamber"))
	_apply_weapon_part_stats(item.get("weapon_stats", {}), str(item.get("name", "")))
	if weapons.is_empty():
		return false
	var weapon: Dictionary = weapons[0]
	return int(weapon.get("projectiles", 1)) >= 2 and Array(weapon.get("mods", [])).size() >= 1 and int(weapon.get("upgrade_rank", 0)) == 0


func _load_visual_textures() -> void:
	player_core_body_texture = _load_png_texture(PLAYER_CORE_BODY_PATH)
	player_left_glove_texture = _load_png_texture(PLAYER_LEFT_GLOVE_PATH)
	player_right_glove_texture = _load_png_texture(PLAYER_RIGHT_GLOVE_PATH)
	player_left_boot_texture = _load_png_texture(PLAYER_LEFT_BOOT_PATH)
	player_right_boot_texture = _load_png_texture(PLAYER_RIGHT_BOOT_PATH)
	zombie_idle_texture = _load_png_texture(ZOMBIE_IDLE_PATH)
	fast_zombie_texture = _load_png_texture(FAST_ZOMBIE_PATH)
	spider_swarm_texture = _load_png_texture(SPIDER_SWARM_PATH)
	thrower_zombie_texture = _load_png_texture(THROWER_ZOMBIE_PATH)
	shield_zombie_texture = _load_png_texture(SHIELD_ZOMBIE_PATH)
	boss_zombie_texture = _load_png_texture(BOSS_ZOMBIE_PATH)
	pickaxe_swing_texture = _load_png_texture(PICKAXE_SWING_PATH)


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Failed to load main scene visual texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _process(delta: float) -> void:
	if mode == MODE_PLAY and paused:
		_ensure_pause_overlay_visible()
	if mode == MODE_PLAY and not paused:
		_update_game(delta)
	if smoke_playtest:
		_update_smoke_playtest(delta)
	queue_redraw()
	_update_hud()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and mode == MODE_PLAY:
		_set_paused(not paused)
		get_viewport().set_input_as_handled()
		return


func _unhandled_input(event: InputEvent) -> void:
	if paused:
		return
	if event.is_action_pressed("dash") and mode == MODE_PLAY and dash_cooldown <= 0.0:
		player["dash_time"] = 0.16
		dash_cooldown = 1.7


func _set_paused(value: bool) -> void:
	paused = value
	if game_ui == null:
		return
	if paused:
		game_ui.show_pause(_current_state_summary(), _active_relic_summary())
	else:
		game_ui.hide_pause()


func _ensure_pause_overlay_visible() -> void:
	if game_ui == null:
		return
	if not game_ui.pause_banner.visible:
		game_ui.show_pause(_current_state_summary(), _active_relic_summary())


func _reset_run(start_playing: bool) -> void:
	mode = MODE_PLAY if start_playing else MODE_START
	elapsed = 0.0
	wave = 1
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	wallets = EconomyRulesScript.fresh_wallet(currency_ids)
	level = 1
	xp = 0.0
	xp_to_next = 14.0
	damage_multiplier = 1.0
	cooldown_multiplier = 1.0
	range_multiplier = 1.0
	currency_drop_multiplier = 1.0
	xp_multiplier = 1.0
	hp_regen = 0.0
	dash_cooldown = 0.0
	screen_shake = 0.0
	paused = false
	if game_ui != null:
		game_ui.hide_pause()
	camera_pos = _clamped_camera_position(WORLD_SIZE * 0.5)
	next_enemy_id = 1
	active_relics.clear()
	relic_counts.clear()
	relic_seen_counts.clear()
	pending_reward_chain.clear()
	active_reward_context.clear()
	reroll_cost = _shop_reroll_cost()
	round_currency_earned = _fresh_currency_amounts()
	rounds_cleared = 0
	spider_relic_packs_this_wave = 0
	run_rerolls = 0
	run_purchase_count = 0
	run_round_clear_ore = 0
	run_purchase_names.clear()
	run_rare_legendary_purchase_names.clear()
	run_kill_count = 0
	run_kills_by_type.clear()
	run_boss_damage = 0.0
	run_boss_defeated = false
	player = {
		"pos": WORLD_SIZE * 0.5,
		"radius": 18.0,
		"hp": 100.0,
		"max_hp": 100.0,
		"speed": 255.0,
		"armor": 0.0,
		"pickup_range": 115.0,
		"hurt_cooldown": 0.0,
		"dash_time": 0.0,
		"moving": false,
		"facing_right": false,
	}
	weapons.clear()
	items.clear()
	shop_stock.clear()
	purchased_shop_item_ids.clear()
	shop_seen_counts.clear()
	shop_visit_seen_item_ids.clear()
	enemies.clear()
	bullets.clear()
	enemy_projectiles.clear()
	pickups.clear()
	spawn_warnings.clear()
	hazard_zones.clear()
	sparks.clear()
	floating_text.clear()
	boss_spawned = false
	selected_weapon_id = ""
	active_choice_generation = 0
	handled_choice_keys.clear()
	_set_run_rule_state(RunRulesScript.fresh_run_state())
	if start_playing:
		_equip_weapon_for_run("drill_tip")
	_render_weapons()


func _round_duration(round_index: int) -> float:
	return RunRulesScript.round_duration(round_index, smoke_playtest, SMOKE_ROUND_DURATION, P1_BOSS_ROUND_DURATION)


func _round_is_boss(round_index: int) -> bool:
	return RunRulesScript.is_boss_round(round_index)


func _shop_reroll_cost() -> int:
	return EconomyRulesScript.shop_reroll_cost(wave, rounds_cleared)


func _update_game(delta: float) -> void:
	elapsed += delta
	wave_timer -= delta
	spawn_timer -= delta
	screen_shake = max(0.0, screen_shake - delta * 10.0)
	dash_cooldown = max(0.0, dash_cooldown - delta)
	player["hurt_cooldown"] = max(0.0, player["hurt_cooldown"] - delta)
	player["dash_time"] = max(0.0, player["dash_time"] - delta)
	if hp_regen > 0.0 and player["hp"] > 0.0:
		player["hp"] = min(player["max_hp"], player["hp"] + hp_regen * delta)

	_move_player(delta)
	_update_camera(delta)
	_spawn_enemies()
	_update_spawn_warnings(delta)
	_update_weapons(delta)
	_update_bullets(delta)
	_update_enemy_projectiles(delta)
	_update_enemies(delta)
	_update_hazard_zones(delta)
	_update_pickups(delta)
	_update_sparks(delta)
	_update_floating_text(delta)

	if not _round_is_boss(wave) and wave_timer <= 0.0:
		_finish_round()
		return

	if player["hp"] <= 0.0:
		_game_over()


func _move_player(delta: float) -> void:
	var direction := Vector2.ZERO
	if smoke_playtest:
		direction = _smoke_direction()
	else:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dash_boost := 2.6 if player["dash_time"] > 0.0 else 1.0
	var pos: Vector2 = player["pos"] + direction * player["speed"] * dash_boost * delta
	pos.x = clamp(pos.x, WORLD_MARGIN, WORLD_SIZE.x - WORLD_MARGIN)
	pos.y = clamp(pos.y, WORLD_MARGIN, WORLD_SIZE.y - WORLD_MARGIN)
	player["pos"] = pos
	player["moving"] = direction.length_squared() > 0.001 or player["dash_time"] > 0.0
	if absf(direction.x) > 0.05:
		player["facing_right"] = direction.x > 0.0


func _update_camera(delta: float) -> void:
	var target := _clamped_camera_position(Vector2(player.get("pos", WORLD_SIZE * 0.5)))
	if camera_pos == Vector2.ZERO:
		camera_pos = target
	var follow_weight := 1.0 - exp(-CAMERA_FOLLOW_SPEED * max(0.0, delta))
	camera_pos = camera_pos.lerp(target, follow_weight)


func _clamped_camera_position(target_center: Vector2) -> Vector2:
	var half_view := VIEW_SIZE * 0.5
	var clamped := target_center
	if WORLD_SIZE.x <= VIEW_SIZE.x:
		clamped.x = WORLD_SIZE.x * 0.5
	else:
		clamped.x = clamp(clamped.x, half_view.x, WORLD_SIZE.x - half_view.x)
	if WORLD_SIZE.y <= VIEW_SIZE.y:
		clamped.y = WORLD_SIZE.y * 0.5
	else:
		clamped.y = clamp(clamped.y, half_view.y, WORLD_SIZE.y - half_view.y)
	return clamped


func _camera_origin() -> Vector2:
	return _clamped_camera_position(camera_pos) - VIEW_SIZE * 0.5


func _visible_world_rect() -> Rect2:
	return Rect2(_camera_origin(), VIEW_SIZE)


func _start_smoke_playtest() -> void:
	smoke_playtest = true
	smoke_elapsed = 0.0
	smoke_choices_taken = 0
	smoke_finishing = false
	_start_run()
	player["max_hp"] = 420.0
	player["hp"] = 420.0
	player["armor"] = 8.0
	player["speed"] = 360.0
	damage_multiplier = 4.2
	cooldown_multiplier = 0.38
	range_multiplier = 1.45
	hp_regen = 2.0


func _update_smoke_playtest(delta: float) -> void:
	if smoke_finishing:
		return

	smoke_elapsed += delta
	if mode == MODE_CHOICE:
		_choose_smoke_option()
	elif mode == MODE_GAME_OVER:
		_finish_smoke_playtest.call_deferred("GAME_OVER")
	elif mode == MODE_VICTORY:
		_finish_smoke_playtest.call_deferred("VICTORY")
	elif smoke_elapsed >= SMOKE_PLAYTEST_DURATION:
		_finish_smoke_playtest.call_deferred("TIMEOUT")


func _smoke_direction() -> Vector2:
	if _round_is_boss(wave):
		var boss := _boss_enemy()
		if not boss.is_empty():
			return (boss["pos"] - player["pos"]).normalized()
	var angle := smoke_elapsed * 1.25
	return Vector2(cos(angle), sin(angle)).normalized()


func _choose_smoke_option() -> void:
	if active_choice_options.is_empty() or active_choice_method.is_empty():
		return

	var selected: Dictionary = {}
	if active_choice_method == "_choose_starter_weapon":
		var desired_weapon := smoke_weapon_id if not smoke_weapon_id.is_empty() else "pickaxe"
		for option in active_choice_options:
			if str(option.get("id", "")) == desired_weapon:
				selected = option
				break
	for option in active_choice_options:
		if not selected.is_empty():
			break
		if (not option.has("cost") or EconomyRulesScript.can_pay(wallets, _option_cost(option), currency_ids)) and not _choice_option_disabled(option):
			selected = option
			break

	if selected.is_empty():
		for i in range(active_choice_options.size() - 1, -1, -1):
			var option: Dictionary = active_choice_options[i]
			if not _choice_option_disabled(option):
				selected = option
				break
	if selected.is_empty():
		return

	smoke_choices_taken += 1
	Callable(self, active_choice_method).call(selected)


func _finish_smoke_playtest(result: String) -> void:
	if smoke_finishing:
		return
	smoke_finishing = true
	var capture_path := "skipped-headless"
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png(SMOKE_PLAYTEST_CAPTURE_PATH)
		capture_path = SMOKE_PLAYTEST_CAPTURE_PATH
	print("SMOKE_PLAYTEST result=%s mode=%s wave=%d level=%d hp=%.1f wallets=\"%s\" enemies=%d pickups=%d choices=%d elapsed=%.2f capture=%s report=\"%s\"" % [
		result,
		mode,
		wave,
		level,
		float(player.get("hp", 0.0)),
		_wallet_balance_summary(),
		enemies.size(),
		pickups.size(),
		smoke_choices_taken,
		elapsed,
		capture_path,
		_run_report_console_summary(),
	])
	get_tree().quit(1 if result == "GAME_OVER" or result == "TIMEOUT" else 0)


func _spawn_enemies() -> void:
	if (wave < MAX_ROUNDS and wave_timer <= 0.0) or spawn_timer > 0.0:
		return

	if _round_is_boss(wave) and not boss_spawned:
		_queue_spawn_warning(_boss_kind_for_round(wave), 1, BOSS_SPAWN_WARNING_DURATION)
		boss_spawned = true
		spawn_timer = 1.8
		return

	if enemies.size() + _pending_spawn_count() >= _enemy_cap():
		spawn_timer = 0.35
		return

	if _should_spawn_checkpoint_elite():
		_queue_spawn_warning("elite_zombie", 1)
		if not spawn_warnings.is_empty():
			spawn_warnings[-1]["checkpoint_elite"] = true
		_set_run_rule_state(RunRulesScript.mark_elite_spawned(run_rule_state))
		spawn_timer = max(0.38, _enemy_spawn_interval("elite_zombie") * 0.82)
		return

	if _should_spawn_elite_zombie():
		_queue_spawn_warning("elite_zombie", 1)
		spawn_timer = max(0.38, _enemy_spawn_interval("elite_zombie") * 0.82)
		return

	var kind := _pick_enemy_kind()
	var pack_size := _enemy_pack_size(kind)
	_queue_spawn_warning(kind, pack_size)
	spawn_timer = _enemy_spawn_interval(kind)


func _spawn_enemy_pack(kind: String, pack_size: int) -> void:
	_spawn_enemy_pack_at(kind, pack_size, _spawn_position(), false)


func _spawn_enemy_pack_at(kind: String, pack_size: int, anchor: Vector2, emerging: bool, checkpoint_elite: bool = false) -> void:
	for i in range(pack_size):
		if enemies.size() >= _enemy_cap():
			return
		var enemy := _make_enemy(kind)
		var spread_radius := 20.0 + float(pack_size) * 5.0 + float(enemy.get("radius", 12.0)) * 0.55
		var angle := TAU * float(i) / float(max(1, pack_size)) + randf_range(-0.28, 0.28)
		enemy["pos"] = anchor + Vector2.RIGHT.rotated(angle) * randf_range(spread_radius * 0.45, spread_radius)
		if emerging:
			enemy["emerge_timer"] = ENEMY_EMERGE_DURATION
			enemy["emerge_duration"] = ENEMY_EMERGE_DURATION
		if checkpoint_elite:
			enemy["checkpoint_elite"] = true
		enemies.append(enemy)


func _queue_spawn_warning(kind: String, pack_size: int, duration: float = SPAWN_WARNING_DURATION) -> void:
	var capped_pack_size: int = min(pack_size, max(0, _enemy_cap() - enemies.size() - _pending_spawn_count()))
	if capped_pack_size <= 0:
		return
	spawn_warnings.append({
		"kind": kind,
		"pack_size": capped_pack_size,
		"pos": _spawn_warning_position(kind),
		"timer": duration,
		"duration": duration,
		"seed": randf() * 1000.0,
	})


func _update_spawn_warnings(delta: float) -> void:
	for i in range(spawn_warnings.size() - 1, -1, -1):
		var warning: Dictionary = spawn_warnings[i]
		warning["timer"] = float(warning.get("timer", 0.0)) - delta
		if float(warning["timer"]) <= 0.0:
			_spawn_enemy_pack_at(str(warning.get("kind", "zombie")), int(warning.get("pack_size", 1)), Vector2(warning.get("pos", player.get("pos", WORLD_SIZE * 0.5))), true, bool(warning.get("checkpoint_elite", false)))
			spawn_warnings.remove_at(i)


func _pending_spawn_count() -> int:
	var count := 0
	for warning in spawn_warnings:
		count += int(warning.get("pack_size", 1))
	return count


func _enemy_cap() -> int:
	var base_cap := 12
	match wave:
		1:
			base_cap = 12
		2:
			base_cap = 15
		3:
			base_cap = 18
		4:
			base_cap = 21
		5:
			base_cap = 8
		6:
			base_cap = 24
		7:
			base_cap = 27
		8:
			base_cap = 29
		9:
			base_cap = 32
		10:
			base_cap = 14
		_:
			base_cap = 24
	return base_cap


func _pick_enemy_kind() -> String:
	var roll := randf()
	match wave:
		1:
			return "zombie"
		2:
			return "fast_zombie" if roll < 0.72 else "zombie"
		3:
			if roll < 0.64:
				return "spider"
			return "fast_zombie" if roll < 0.86 else "zombie"
		4:
			if roll < 0.46:
				return "thrower"
			if roll < 0.70:
				return "spider"
			return "fast_zombie" if roll < 0.88 else "zombie"
		6:
			if roll < 0.30:
				return "shield_zombie"
			if roll < 0.56:
				return "thrower"
			if roll < 0.78:
				return "fast_zombie"
			return "zombie"
		7:
			if roll < 0.25:
				return "shield_zombie"
			if roll < 0.48:
				return "toxic_spider"
			if roll < 0.66:
				return "thrower"
			if roll < 0.84:
				return "fast_zombie"
			return "zombie"
		8, 9:
			if roll < 0.21:
				return "shield_zombie"
			if roll < 0.42:
				return "toxic_spider"
			if roll < 0.58:
				return "bomb_miner"
			if roll < 0.74:
				return "thrower"
			if roll < 0.90:
				return "fast_zombie"
			return "zombie"
		_:
			if roll < 0.30:
				return "thrower"
			if roll < 0.56:
				return "spider"
			if roll < 0.78:
				return "fast_zombie"
			return "zombie"


func _enemy_pack_size(kind: String) -> int:
	if kind == "spider":
		return randi_range(4, 5) if wave < 8 else randi_range(3, 4)
	if kind == "toxic_spider":
		return randi_range(2, 3)
	if kind == "shield_zombie" or kind == "bomb_miner":
		return 1
	if _round_is_boss(wave) and kind != "thrower":
		return 2 if randf() < 0.35 else 1
	return 1


func _enemy_spawn_interval(kind: String) -> float:
	var interval := 1.0
	match wave:
		1:
			interval = 1.05
		2:
			interval = 0.84
		3:
			interval = 1.12 if kind == "spider" else 0.92
		4:
			interval = 1.18 if kind == "thrower" else 0.96
		5:
			interval = 1.5
		6:
			interval = 1.05
		7:
			interval = 1.0
		8:
			interval = 0.95
		9:
			interval = 0.88
		10:
			interval = 1.35
		_:
			interval = 1.36
	if smoke_playtest:
		interval *= 0.62
	return max(0.32, interval)


func _spawn_position() -> Vector2:
	var side := randi_range(0, 3)
	if side == 0:
		return Vector2(-30.0, randf() * WORLD_SIZE.y)
	if side == 1:
		return Vector2(WORLD_SIZE.x + 30.0, randf() * WORLD_SIZE.y)
	if side == 2:
		return Vector2(randf() * WORLD_SIZE.x, -30.0)
	return Vector2(randf() * WORLD_SIZE.x, WORLD_SIZE.y + 30.0)


func _spawn_warning_position(kind: String) -> Vector2:
	var visible := _visible_world_rect()
	var margin := 74.0
	var top_margin := 120.0
	var radius_bonus := 30.0
	if _is_boss_type(kind):
		radius_bonus = 72.0
	elif kind == "elite_zombie":
		radius_bonus = 48.0
	var min_x: float = maxf(WORLD_MARGIN + radius_bonus, visible.position.x + margin)
	var max_x: float = minf(WORLD_SIZE.x - WORLD_MARGIN - radius_bonus, visible.position.x + visible.size.x - margin)
	var min_y: float = maxf(WORLD_MARGIN + radius_bonus, visible.position.y + top_margin)
	var max_y: float = minf(WORLD_SIZE.y - WORLD_MARGIN - radius_bonus, visible.position.y + visible.size.y - margin)
	if max_x < min_x:
		min_x = WORLD_MARGIN + radius_bonus
		max_x = WORLD_SIZE.x - WORLD_MARGIN - radius_bonus
	if max_y < min_y:
		min_y = WORLD_MARGIN + radius_bonus
		max_y = WORLD_SIZE.y - WORLD_MARGIN - radius_bonus

	var chosen := Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
	var min_distance := 150.0 if kind != "boss" else 230.0
	for attempt in range(8):
		var candidate := Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
		if candidate.distance_to(player["pos"]) >= min_distance:
			return candidate
		if candidate.distance_to(player["pos"]) > chosen.distance_to(player["pos"]):
			chosen = candidate
	return chosen


func _make_enemy(kind: String) -> Dictionary:
	var hp := 24.0
	var radius: float = 16.0
	var speed := 92.0
	var damage: float = 9.0
	var color := Color("#b95b4b")
	var armor := 0.0
	var dropped_xp := 0
	var desired_range := 0.0
	var attack_cooldown := 0.0

	match kind:
		"fast_zombie":
			hp = 20.0
			radius = 14.0
			speed = 138.0
			damage = 7.0
			color = Color("#d68149")
		"spider":
			hp = 8.0
			radius = 9.0
			speed = 124.0
			damage = 4.0
			color = Color("#6f9f61")
		"thrower":
			hp = 36.0
			radius = 18.0
			speed = 66.0
			damage = 6.0
			color = Color("#7e8a76")
			desired_range = 360.0
			attack_cooldown = 2.15
		"shield_zombie":
			hp = 92.0
			radius = 25.0
			speed = 48.0
			damage = 9.0
			armor = 2.0
			color = Color("#5f7167")
		"toxic_spider":
			hp = 13.0
			radius = 10.0
			speed = 132.0
			damage = 3.0
			color = Color("#8fc45b")
		"bomb_miner":
			hp = 42.0
			radius = 18.0
			speed = 54.0
			damage = 12.0
			color = Color("#c9823a")
		"elite_zombie":
			hp = 82.0
			radius = 25.0
			speed = 62.0
			damage = 13.0
			armor = 1.0
			color = Color("#8b7254")
		"boss":
			hp = 380.0
			radius = 42.0
			speed = 48.0
			damage = 16.0
			armor = 3.0
			color = Color("#6f4f86")
		"mid_boss":
			hp = 680.0
			radius = 42.0
			speed = 70.0
			damage = 16.0
			armor = 3.0
			color = Color("#6f4f86")
		"final_boss":
			hp = 1550.0
			radius = 48.0
			speed = 74.0
			damage = 18.0
			armor = 4.0
			color = Color("#7d456a")
		_:
			kind = "zombie"

	hp *= _contract_enemy_hp_multiplier(kind)
	damage *= _contract_enemy_damage_multiplier(kind)
	speed *= _contract_enemy_speed_multiplier(kind)
	if kind == "thrower":
		attack_cooldown = max(0.72, attack_cooldown * _contract_thrower_cooldown_multiplier())
	var elite := _should_make_contract_elite(kind)
	if elite:
		hp *= 1.45
		damage *= 1.18
		speed *= 1.08
		armor += 1.0
	var currency_drop := DemoContentScript.enemy_currency_profile(kind)

	var enemy_id := next_enemy_id
	next_enemy_id += 1

	var enemy := {
		"id": enemy_id,
		"type": kind,
		"pos": _spawn_position(),
		"radius": radius,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"damage": damage,
		"armor": armor,
		"color": color,
		"currency_drop": currency_drop,
		"xp": dropped_xp,
		"desired_range": desired_range,
		"attack_timer": randf_range(0.25, max(0.35, attack_cooldown)),
		"attack_cooldown": attack_cooldown,
		"knockback_velocity": Vector2.ZERO,
		"hit_flash": 0.0,
		"hit_flash_color": Color("#f5efe3"),
		"emerge_timer": 0.0,
		"emerge_duration": ENEMY_EMERGE_DURATION,
		"elite": elite,
	}
	if _is_boss_type(kind):
		enemy["pattern_timer"] = 1.25
		enemy["charge_state"] = "idle"
		enemy["charge_timer"] = 0.0
		enemy["charge_dir"] = Vector2.ZERO
		enemy["summon_count"] = 0
		enemy["bullet_pattern_used"] = false
	if kind == "bomb_miner":
		enemy["bomb_state"] = "approach"
		enemy["bomb_timer"] = 0.0
		enemy["charge_dir"] = Vector2.ZERO
	return enemy


func _update_weapons(delta: float) -> void:
	for weapon in weapons:
		weapon["timer"] -= delta
		if weapon["timer"] <= 0.0:
			var effective_range: float = weapon["range"] * range_multiplier
			var target := _nearest_enemy(effective_range)
			if not target.is_empty():
				_fire_weapon(weapon, target, effective_range)
				weapon["timer"] = weapon["cooldown"] * cooldown_multiplier


func _nearest_enemy(search_range: float) -> Dictionary:
	if _round_is_boss(wave):
		var boss := _boss_in_range(search_range)
		if not boss.is_empty():
			return boss

	var best := {}
	var best_distance := search_range * search_range
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		if _enemy_is_emerging(enemy):
			continue
		var distance: float = player["pos"].distance_squared_to(enemy["pos"])
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _boss_in_range(search_range: float) -> Dictionary:
	var best := {}
	var best_distance := search_range * search_range
	for enemy in enemies:
		if not _is_boss_type(str(enemy.get("type", ""))):
			continue
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		if _enemy_is_emerging(enemy):
			continue
		var distance: float = player["pos"].distance_squared_to(enemy["pos"])
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _boss_enemy() -> Dictionary:
	for enemy in enemies:
		if _is_boss_type(str(enemy.get("type", ""))):
			return enemy
	return {}


func _boss_kind_for_round(round_index: int) -> String:
	return "mid_boss" if round_index == 5 else "final_boss"


func _is_boss_type(type: String) -> bool:
	return type == "boss" or type == "mid_boss" or type == "final_boss"


func _fire_weapon(weapon: Dictionary, target: Dictionary, effective_range: float) -> void:
	match str(weapon.get("fire_type", "bullet")):
		"arc":
			_fire_arc(weapon, effective_range)
		"slash":
			_fire_slash(weapon, effective_range)
		"pickaxe_slash":
			_fire_pickaxe_slash(weapon, target, effective_range)
		"lantern_pulse":
			_fire_lantern_pulse(weapon, effective_range)
		"explosive":
			_fire_projectiles(weapon, target, effective_range, true)
		_:
			_fire_projectiles(weapon, target, effective_range, false)


func _fire_projectiles(weapon: Dictionary, target: Dictionary, effective_range: float, explosive: bool) -> void:
	var origin: Vector2 = player["pos"]
	var base_angle: float = (target["pos"] - origin).angle()
	var projectile_count := int(weapon.get("projectiles", 1))
	var spread := float(weapon.get("spread", 0.0))
	var pierce_count := int(weapon.get("pierce", 0))
	var splash_radius := float(weapon.get("splash", 0.0))
	var armor_pierce := float(weapon.get("armor_pierce", 0.0))
	var center_projectile := bool(weapon.get("center_projectile", false))
	var has_rapid_feedback := _weapon_has_mod(weapon, "급속 방아쇠")
	for i in range(projectile_count):
		var offset := _projectile_spread_offset(i, projectile_count, spread, center_projectile)
		var direction := Vector2.RIGHT.rotated(base_angle + offset)
		var bullet_radius := 5.0
		if str(weapon.get("shape", "")) == "nail":
			bullet_radius = 3.5
		elif explosive:
			bullet_radius = 8.0
		elif weapon["id"] == "drill":
			bullet_radius = 7.0
		bullets.append({
			"pos": origin + direction * 18.0,
			"velocity": direction * weapon["speed"],
			"radius": bullet_radius,
			"life": effective_range / max(1.0, weapon["speed"]),
			"damage": weapon["damage"] * damage_multiplier,
			"color": weapon["color"],
			"pierce": pierce_count,
			"initial_pierce": pierce_count,
			"splash": splash_radius,
			"armor_pierce": armor_pierce,
			"knockback": float(weapon.get("knockback", 0.0)),
			"shape": str(weapon.get("shape", "round")),
			"pierce_feedback": pierce_count > 0,
			"splash_feedback": splash_radius > 0.0,
			"armor_feedback": armor_pierce > 0.0,
			"rapid_feedback": has_rapid_feedback,
			"hit_ids": [],
		})
		_add_muzzle_feedback(origin, direction, weapon, has_rapid_feedback)


func _projectile_spread_offset(index: int, projectile_count: int, spread: float, center_projectile: bool) -> float:
	if projectile_count <= 1 or spread <= 0.0:
		return 0.0
	if not center_projectile:
		return lerp(-spread, spread, float(index) / float(projectile_count - 1))
	if index == 0:
		return 0.0
	var lane := int(ceil(float(index) / 2.0))
	var side := 1.0 if index % 2 == 1 else -1.0
	return spread * float(lane) * side


func _fire_arc(weapon: Dictionary, effective_range: float) -> void:
	var targets := []
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or _enemy_is_emerging(enemy):
			continue
		if player["pos"].distance_squared_to(enemy["pos"]) <= effective_range * effective_range:
			targets.append(enemy)
	targets.sort_custom(func(a, b): return player["pos"].distance_squared_to(a["pos"]) < player["pos"].distance_squared_to(b["pos"]))

	var count = min(4, targets.size())
	for i in range(count):
		var target = targets[i]
		var push_dir: Vector2 = (Vector2(target["pos"]) - Vector2(player["pos"])).normalized()
		_hurt_enemy(target, weapon["damage"] * damage_multiplier, target["pos"], 0.0, push_dir, "arc")
		sparks.append({
			"line": true,
			"from": player["pos"],
			"to": target["pos"],
			"life": 0.16,
			"max_life": 0.16,
			"color": weapon["color"],
		})


func _fire_slash(weapon: Dictionary, effective_range: float) -> void:
	var targets := []
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or _enemy_is_emerging(enemy):
			continue
		if player["pos"].distance_squared_to(enemy["pos"]) <= effective_range * effective_range:
			targets.append(enemy)
	targets.sort_custom(func(a, b): return player["pos"].distance_squared_to(a["pos"]) < player["pos"].distance_squared_to(b["pos"]))

	var count = min(5, targets.size())
	for i in range(count):
		var target = targets[i]
		var push_dir: Vector2 = (Vector2(target["pos"]) - Vector2(player["pos"])).normalized()
		_hurt_enemy(target, weapon["damage"] * damage_multiplier, target["pos"], 0.0, push_dir, "slash")
		sparks.append({
			"line": true,
			"from": player["pos"] + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)),
			"to": target["pos"],
			"life": 0.12,
			"max_life": 0.12,
			"color": weapon["color"],
		})
	if count == 0:
		_add_spark(player["pos"], weapon["color"], 4)


func _fire_pickaxe_slash(weapon: Dictionary, target: Dictionary, effective_range: float) -> void:
	var origin: Vector2 = player["pos"]
	var base_direction: Vector2 = (Vector2(target["pos"]) - origin).normalized()
	if base_direction.length_squared() <= 0.001:
		base_direction = Vector2.RIGHT
	var swing_count: int = max(1, int(weapon.get("projectiles", 1)))
	var pierce_count: int = max(0, int(weapon.get("pierce", 0)))
	var spread := float(weapon.get("spread", 0.24))
	var half_angle := 0.48
	var armor_pierce := float(weapon.get("armor_pierce", 0.0))
	var splash_radius := float(weapon.get("splash", 0.0))
	for swing in range(swing_count):
		var direction := base_direction.rotated(_projectile_spread_offset(swing, swing_count, spread, true))
		var hit_count := 0
		var candidates := []
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0 or _enemy_is_emerging(enemy):
				continue
			var to_enemy: Vector2 = Vector2(enemy["pos"]) - origin
			var distance := to_enemy.length()
			if distance > effective_range + float(enemy.get("radius", 0.0)):
				continue
			if absf(direction.angle_to(to_enemy.normalized())) > half_angle:
				continue
			candidates.append({"enemy": enemy, "distance": distance})
		candidates.sort_custom(func(a, b): return float(a["distance"]) < float(b["distance"]))
		var max_hits: int = 4 + pierce_count
		for candidate in candidates:
			if hit_count >= max_hits:
				break
			var enemy: Dictionary = candidate["enemy"]
			var push_dir: Vector2 = (Vector2(enemy["pos"]) - origin).normalized()
			_hurt_enemy(enemy, weapon["damage"] * damage_multiplier, enemy["pos"], armor_pierce, push_dir, "pierce" if pierce_count > 0 else "slash")
			if splash_radius > 0.0:
				_damage_enemy_splash(Vector2(enemy["pos"]), splash_radius, weapon["damage"] * damage_multiplier * 0.42, armor_pierce, push_dir)
			hit_count += 1
		_add_pickaxe_swing_feedback(origin, direction, effective_range, Color(weapon.get("color", Color("#f2cf66"))), hit_count)


func _fire_lantern_pulse(weapon: Dictionary, effective_range: float) -> void:
	var origin: Vector2 = player["pos"]
	var pulse_count: int = max(1, int(weapon.get("projectiles", 1)))
	var pierce_count: int = max(0, int(weapon.get("pierce", 0)))
	var armor_pierce := float(weapon.get("armor_pierce", 0.0))
	var splash_radius := float(weapon.get("splash", 0.0))
	for pulse_index in range(pulse_count):
		var radius := effective_range + float(pulse_index) * 34.0
		var damage_scale := 1.0 if pulse_index == 0 else 0.72
		var hit_count := 0
		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0 or _enemy_is_emerging(enemy):
				continue
			var enemy_pos: Vector2 = enemy["pos"]
			if origin.distance_to(enemy_pos) > radius + float(enemy.get("radius", 0.0)):
				continue
			var push_dir := (enemy_pos - origin).normalized()
			_hurt_enemy(enemy, weapon["damage"] * damage_multiplier * damage_scale, enemy_pos, armor_pierce, push_dir, "pierce" if pierce_count > 0 else "lantern")
			if splash_radius > 0.0:
				_damage_enemy_splash(enemy_pos, splash_radius, weapon["damage"] * damage_multiplier * 0.36, armor_pierce, push_dir)
			hit_count += 1
		_add_lantern_pulse_feedback(origin, radius, Color(weapon.get("color", Color("#e6b85c"))), pulse_index, hit_count)


func _damage_enemy_splash(pos: Vector2, radius: float, damage: float, armor_pierce: float, direct_push: Vector2) -> void:
	if radius <= 0.0:
		return
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or _enemy_is_emerging(enemy):
			continue
		var enemy_pos: Vector2 = enemy["pos"]
		var distance := pos.distance_to(enemy_pos)
		if distance <= radius:
			var falloff: float = 1.0 - min(0.45, distance / radius * 0.45)
			var splash_push := (enemy_pos - pos).normalized()
			if splash_push.length_squared() <= 0.001:
				splash_push = direct_push
			_hurt_enemy(enemy, damage * falloff, enemy_pos, armor_pierce, splash_push, "splash")
	_add_hazard_ring(pos, radius, Color("#f0643b"), 0.18)


func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		var bullet_pos: Vector2 = bullet["pos"]
		var bullet_velocity: Vector2 = bullet["velocity"]
		bullet_pos += bullet_velocity * delta
		bullet["pos"] = bullet_pos
		bullet["life"] -= delta

		for enemy in enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			if _enemy_is_emerging(enemy):
				continue
			if bullet["hit_ids"].has(enemy["id"]):
				continue
			var enemy_pos: Vector2 = enemy["pos"]
			var hit_radius: float = float(bullet["radius"]) + float(enemy["radius"])
			if bullet_pos.distance_squared_to(enemy_pos) <= hit_radius * hit_radius:
				bullet["hit_ids"].append(enemy["id"])
				if float(bullet.get("splash", 0.0)) > 0.0:
					_explode_bullet(bullet, bullet_pos, int(enemy["id"]))
					bullet["pierce"] -= 1
					if bullet["pierce"] < 0:
						bullet["life"] = 0.0
						break
				else:
					var push_dir: Vector2 = bullet_velocity.normalized()
					_hurt_enemy(enemy, bullet["damage"], bullet_pos, float(bullet.get("armor_pierce", 0.0)), push_dir, _bullet_hit_feedback(bullet, enemy, false, true))
					bullet["pierce"] -= 1
					if bullet["pierce"] < 0:
						bullet["life"] = 0.0
						break

		if bullet["life"] <= 0.0:
			bullets.remove_at(i)


func _update_enemy_projectiles(delta: float) -> void:
	for i in range(enemy_projectiles.size() - 1, -1, -1):
		var projectile = enemy_projectiles[i]
		projectile["pos"] += projectile["velocity"] * delta
		projectile["life"] -= delta

		if projectile["pos"].distance_squared_to(player["pos"]) <= pow(projectile["radius"] + player["radius"], 2.0):
			if player["hurt_cooldown"] <= 0.0:
				_apply_player_damage(float(projectile["damage"]), "투사체", Color("#f0643b"), 0.45)
			_add_spark(projectile["pos"], projectile["color"], 8)
			enemy_projectiles.remove_at(i)
			continue

		if projectile["life"] <= 0.0 or not Rect2(Vector2(-80, -80), WORLD_SIZE + Vector2(160, 160)).has_point(projectile["pos"]):
			enemy_projectiles.remove_at(i)


func _apply_player_damage(raw_damage: float, label: String = "", color: Color = Color("#f0643b"), cooldown: float = 0.55, armor_scale: float = 1.0) -> float:
	var damage: float = max(1.0, raw_damage - float(player.get("armor", 0.0)) * armor_scale)
	player["hp"] = float(player.get("hp", 0.0)) - damage
	player["hurt_cooldown"] = cooldown
	screen_shake = max(screen_shake, 0.8)
	var prefix := "" if label.is_empty() else "%s " % label
	_add_floating_text("%s-%d" % [prefix, int(round(damage))], Vector2(player.get("pos", Vector2.ZERO)) + Vector2(0, -28), color)
	return damage


func _pattern_damage(base_damage: float) -> float:
	return base_damage


func _update_hazard_zones(delta: float) -> void:
	for i in range(hazard_zones.size() - 1, -1, -1):
		var zone: Dictionary = hazard_zones[i]
		zone["life"] = float(zone.get("life", 0.0)) - delta
		zone["tick"] = max(0.0, float(zone.get("tick", 0.0)) - delta)
		if float(zone["life"]) <= 0.0:
			hazard_zones.remove_at(i)
			continue
		var pos: Vector2 = zone.get("pos", Vector2.ZERO)
		var radius := float(zone.get("radius", 64.0))
		if Vector2(player.get("pos", Vector2.ZERO)).distance_to(pos) <= radius and float(zone.get("tick", 0.0)) <= 0.0:
			_apply_player_damage(float(zone.get("damage", 4.0)), str(zone.get("label", "독")), Color(zone.get("color", Color("#93c96d"))), 0.30, 0.45)
			zone["tick"] = 0.55


func _spawn_poison_zone(pos: Vector2, radius: float, duration: float, damage: float, color: Color = Color("#93c96d")) -> void:
	hazard_zones.append({
		"pos": pos,
		"radius": radius,
		"life": duration,
		"max_life": duration,
		"damage": damage,
		"tick": 0.0,
		"color": color,
		"label": "독",
	})


func _add_hazard_ring(pos: Vector2, radius: float, color: Color, duration: float) -> void:
	sparks.append({
		"line": false,
		"pos": pos,
		"velocity": Vector2.ZERO,
		"life": duration,
		"max_life": duration,
		"color": color,
		"radius": radius,
		"ring": true,
		"width": 4.0,
	})


func _add_pickaxe_swing_feedback(origin: Vector2, direction: Vector2, radius: float, color: Color, hit_count: int) -> void:
	var max_life := 0.24
	sparks.append({
		"type": "pickaxe_swing",
		"line": false,
		"pos": origin,
		"velocity": Vector2.ZERO,
		"direction": direction,
		"radius": radius,
		"life": max_life,
		"max_life": max_life,
		"color": color,
		"hit_count": hit_count,
	})
	for i in range(max(3, 5 + hit_count * 2)):
		var angle := direction.angle() + randf_range(-0.52, 0.52)
		var distance := randf_range(radius * 0.35, radius)
		sparks.append({
			"line": false,
			"pos": origin + Vector2.RIGHT.rotated(angle) * distance,
			"velocity": Vector2.RIGHT.rotated(angle) * randf_range(32.0, 110.0),
			"life": randf_range(0.12, 0.24),
			"max_life": 0.24,
			"color": color,
		})


func _add_lantern_pulse_feedback(origin: Vector2, radius: float, color: Color, pulse_index: int, hit_count: int) -> void:
	var ring_color := color
	ring_color.a = 0.72 if pulse_index == 0 else 0.52
	sparks.append({
		"line": false,
		"pos": origin,
		"velocity": Vector2.ZERO,
		"life": 0.34,
		"max_life": 0.34,
		"color": ring_color,
		"radius": radius,
		"ring": true,
		"width": 5.0 if pulse_index == 0 else 3.2,
	})
	for i in range(8 + hit_count * 2):
		var angle := TAU * float(i) / float(max(1, 8 + hit_count * 2))
		var spark_pos := origin + Vector2.RIGHT.rotated(angle) * randf_range(radius * 0.18, radius * 0.84)
		sparks.append({
			"line": false,
			"pos": spark_pos,
			"velocity": Vector2.RIGHT.rotated(angle) * randf_range(20.0, 90.0),
			"life": randf_range(0.18, 0.32),
			"max_life": 0.32,
			"color": color,
		})


func _explode_bullet(bullet: Dictionary, pos: Vector2, direct_hit_id: int = -1) -> void:
	var splash := float(bullet.get("splash", 0.0))
	if splash <= 0.0:
		return
	for enemy in enemies:
		if int(enemy.get("id", -1)) == direct_hit_id:
			var direct_push: Vector2 = Vector2(bullet.get("velocity", Vector2.RIGHT)).normalized()
			_hurt_enemy(enemy, bullet["damage"], enemy["pos"], float(bullet.get("armor_pierce", 0.0)), direct_push, _bullet_hit_feedback(bullet, enemy, true, true))
			continue
		var distance := pos.distance_to(enemy["pos"])
		if distance <= splash:
			var falloff: float = 1.0 - min(0.45, distance / splash * 0.45)
			var splash_push: Vector2 = (Vector2(enemy["pos"]) - pos).normalized()
			_hurt_enemy(enemy, bullet["damage"] * falloff, enemy["pos"], float(bullet.get("armor_pierce", 0.0)), splash_push, _bullet_hit_feedback(bullet, enemy, true, false))
	_add_spark(pos, _splash_feedback_color(bullet), 24)
	_add_directional_sparks(pos, Vector2(bullet.get("velocity", Vector2.RIGHT)).normalized(), _splash_feedback_color(bullet), 12)
	sparks.append({
		"line": false,
		"pos": pos,
		"velocity": Vector2.ZERO,
		"life": 0.26,
		"max_life": 0.26,
		"color": _splash_feedback_color(bullet),
		"radius": splash,
		"ring": true,
		"width": 4.5,
	})


func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and not _update_enemy_emerge(enemy, delta):
			_update_enemy_behavior(enemy, delta)
	_apply_enemy_separation(delta)

	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if enemy["hp"] <= 0.0:
			var defeated_type := str(enemy.get("type", "zombie"))
			_record_enemy_defeat(enemy)
			_drop_pickups(enemy)
			_trigger_enemy_death_pattern(enemy)
			_add_spark(enemy["pos"], enemy["color"], 14)
			enemies.remove_at(i)
			if _is_boss_type(defeated_type):
				if wave >= MAX_ROUNDS:
					_victory()
				else:
					_finish_round()
				return
			continue

		if _enemy_is_emerging(enemy):
			continue
		var direction: Vector2 = (player["pos"] - enemy["pos"]).normalized()
		var touch_distance: float = player["radius"] + enemy["radius"]
		if enemy["pos"].distance_squared_to(player["pos"]) <= touch_distance * touch_distance:
			if player["hurt_cooldown"] <= 0.0:
				if str(enemy.get("type", "")) == "bomb_miner":
					_trigger_bomb_miner_explosion(enemy)
				else:
					_apply_player_damage(float(enemy["damage"]), "", Color("#f0643b"), 0.55)
			enemy["pos"] += -direction * 70.0 * delta


func _trigger_enemy_death_pattern(enemy: Dictionary) -> void:
	var type := str(enemy.get("type", ""))
	if type == "toxic_spider":
		_spawn_poison_zone(Vector2(enemy["pos"]), 58.0, _toxic_zone_duration(), 3.6)


func _toxic_zone_duration() -> float:
	return 3.4 + 0.45 * float(_relic_count("viscous_poison_vein"))


func _update_enemy_behavior(enemy: Dictionary, delta: float) -> void:
	var type := str(enemy.get("type", "zombie"))
	enemy["hit_flash"] = max(0.0, float(enemy.get("hit_flash", 0.0)) - delta * 7.5)
	var to_player: Vector2 = player["pos"] - enemy["pos"]
	var distance: float = max(1.0, to_player.length())
	var direction: Vector2 = to_player / distance

	if type == "bomb_miner":
		_update_bomb_miner_behavior(enemy, delta, direction, distance)
	elif _is_boss_type(type):
		_update_boss_behavior(enemy, delta, direction, distance)
	elif type == "thrower":
		var desired_range := float(enemy.get("desired_range", 360.0))
		if distance > desired_range * 1.08:
			enemy["pos"] += direction * enemy["speed"] * delta
		elif distance < desired_range * 0.62:
			enemy["pos"] -= direction * enemy["speed"] * 0.78 * delta
		else:
			var strafe: Vector2 = direction.rotated(PI * 0.5)
			enemy["pos"] += strafe * sin(elapsed * 2.4 + float(enemy["id"])) * enemy["speed"] * 0.24 * delta

		enemy["attack_timer"] -= delta
		if enemy["attack_timer"] <= 0.0 and distance < 560.0:
			_throw_enemy_rock(enemy, direction)
			enemy["attack_timer"] = float(enemy.get("attack_cooldown", 1.75))
	else:
		enemy["pos"] += direction * enemy["speed"] * delta

	var knockback_velocity: Vector2 = enemy.get("knockback_velocity", Vector2.ZERO)
	if knockback_velocity.length_squared() > 1.0:
		enemy["pos"] += knockback_velocity * delta
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 720.0 * delta)
	else:
		knockback_velocity = Vector2.ZERO
	enemy["knockback_velocity"] = knockback_velocity

	var pos: Vector2 = enemy["pos"]
	pos.x = clamp(pos.x, -60.0, WORLD_SIZE.x + 60.0)
	pos.y = clamp(pos.y, -60.0, WORLD_SIZE.y + 60.0)
	enemy["pos"] = pos


func _update_bomb_miner_behavior(enemy: Dictionary, delta: float, direction: Vector2, distance: float) -> void:
	var state := str(enemy.get("bomb_state", "approach"))
	match state:
		"approach":
			if distance <= 210.0:
				enemy["bomb_state"] = "windup"
				enemy["bomb_timer"] = _bomb_windup_duration()
				enemy["charge_dir"] = direction
			else:
				enemy["pos"] += direction * enemy["speed"] * delta
		"windup":
			enemy["bomb_timer"] = float(enemy.get("bomb_timer", 0.0)) - delta
			if float(enemy["bomb_timer"]) <= 0.0:
				enemy["bomb_state"] = "charge"
				enemy["bomb_timer"] = 0.46
				enemy["charge_dir"] = direction
		"charge":
			var charge_dir: Vector2 = enemy.get("charge_dir", direction)
			enemy["pos"] += charge_dir.normalized() * 330.0 * delta
			enemy["bomb_timer"] = float(enemy.get("bomb_timer", 0.0)) - delta
			if float(enemy["bomb_timer"]) <= 0.0:
				_trigger_bomb_miner_explosion(enemy)
		_:
			enemy["pos"] += direction * enemy["speed"] * delta


func _bomb_windup_duration() -> float:
	return max(0.42, 0.82 - 0.12 * float(_relic_count("shortened_fuse")))


func _trigger_bomb_miner_explosion(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
	var radius := 82.0
	_add_hazard_ring(pos, radius, Color("#f0643b"), 0.22)
	if Vector2(player.get("pos", Vector2.ZERO)).distance_to(pos) <= radius and float(player.get("hurt_cooldown", 0.0)) <= 0.0:
		_apply_player_damage(_pattern_damage(24.0), "폭발", Color("#f0643b"))
	for other in enemies:
		if int(other.get("id", -1)) == int(enemy.get("id", -2)):
			continue
		if float(other.get("hp", 0.0)) <= 0.0:
			continue
		if Vector2(other.get("pos", Vector2.ZERO)).distance_to(pos) <= radius:
			var push_dir := (Vector2(other.get("pos", Vector2.ZERO)) - pos).normalized()
			_hurt_enemy(other, 10.0, other["pos"], 0.0, push_dir, "splash")
	enemy["hp"] = 0.0
	screen_shake = max(screen_shake, 1.1)


func _update_boss_behavior(enemy: Dictionary, delta: float, direction: Vector2, distance: float) -> void:
	var type := str(enemy.get("type", "mid_boss"))
	var charge_state := str(enemy.get("charge_state", "idle"))
	if charge_state == "windup":
		enemy["charge_timer"] = float(enemy.get("charge_timer", 0.0)) - delta
		if float(enemy["charge_timer"]) <= 0.0:
			enemy["charge_state"] = "charge"
			enemy["charge_timer"] = 0.38
		return
	if charge_state == "charge":
		var charge_dir: Vector2 = enemy.get("charge_dir", direction)
		enemy["pos"] += charge_dir.normalized() * (390.0 if type == "final_boss" else 340.0) * delta
		enemy["charge_timer"] = float(enemy.get("charge_timer", 0.0)) - delta
		if float(enemy["charge_timer"]) <= 0.0:
			enemy["charge_state"] = "idle"
			enemy["pattern_timer"] = _boss_pattern_interval(enemy)
		return

	enemy["pattern_timer"] = float(enemy.get("pattern_timer", 1.0)) - delta
	if float(enemy["pattern_timer"]) <= 0.0:
		_execute_boss_pattern(enemy)
		return

	var move_speed: float = float(enemy.get("speed", 44.0))
	if distance > 260.0:
		enemy["pos"] += direction * move_speed * delta
	else:
		var strafe := direction.rotated(PI * 0.5)
		enemy["pos"] += strafe * sin(elapsed * 1.4 + float(enemy["id"])) * move_speed * 0.34 * delta


func _execute_boss_pattern(enemy: Dictionary) -> void:
	var type := str(enemy.get("type", "mid_boss"))
	var phase := _boss_phase(enemy)
	var pattern_index := int(enemy.get("pattern_index", 0))
	var choices: Array[String] = ["charge", "pool"]
	if type == "mid_boss":
		choices = ["charge", "pool", "summon"]
	else:
		if phase >= 2:
			choices.append("summon")
		if phase >= 3:
			choices.append("barrage")
	var pattern: String = choices[pattern_index % choices.size()]
	enemy["pattern_index"] = pattern_index + 1
	match pattern:
		"charge":
			_start_boss_charge(enemy)
		"pool":
			_spawn_poison_zone(Vector2(enemy.get("pos", Vector2.ZERO)), BOSS_POOL_RADIUS, 3.8, _pattern_damage(5.0), Color("#7560a8"))
			enemy["pattern_timer"] = _boss_pattern_interval(enemy)
		"summon":
			_boss_summon(enemy)
			enemy["pattern_timer"] = _boss_pattern_interval(enemy)
		"barrage":
			_boss_barrage(enemy)
			enemy["pattern_timer"] = _boss_pattern_interval(enemy)


func _start_boss_charge(enemy: Dictionary) -> void:
	var direction := (Vector2(player.get("pos", Vector2.ZERO)) - Vector2(enemy.get("pos", Vector2.ZERO))).normalized()
	enemy["charge_dir"] = direction
	enemy["charge_state"] = "windup"
	enemy["charge_timer"] = 0.72
	_add_line_spark(enemy["pos"], enemy["pos"] + direction * 190.0, Color("#f0643b"), 0.34, 5.5)


func _boss_pattern_interval(enemy: Dictionary) -> float:
	var base := 2.35 if str(enemy.get("type", "")) == "final_boss" else 2.55
	return max(1.35, base - 0.20 * float(_relic_count("awakened_overseer")))


func _boss_phase(enemy: Dictionary) -> int:
	var ratio := clampf(float(enemy.get("hp", 0.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0))), 0.0, 1.0)
	if ratio <= 0.35:
		return 3
	if ratio <= 0.70:
		return 2
	return 1


func _boss_summon(enemy: Dictionary) -> void:
	var boss_pos: Vector2 = enemy.get("pos", WORLD_SIZE * 0.5)
	var type := str(enemy.get("type", "mid_boss"))
	var summon_count := int(enemy.get("summon_count", 0))
	if type == "mid_boss":
		for i in range(randi_range(1, 2)):
			_spawn_enemy_pack_at("shield_zombie", 1, boss_pos + Vector2.RIGHT.rotated(randf() * TAU) * 92.0, true)
	else:
		if summon_count >= 4:
			return
		var candidates: Array[String] = ["shield_zombie", "fast_zombie", "toxic_spider", "bomb_miner"]
		var kind: String = candidates[randi_range(0, candidates.size() - 1)]
		var pack := 1
		if kind == "fast_zombie":
			pack = 2
		elif kind == "toxic_spider":
			pack = randi_range(2, 3)
		_spawn_enemy_pack_at(kind, pack, boss_pos + Vector2.RIGHT.rotated(randf() * TAU) * 116.0, true)
		enemy["summon_count"] = summon_count + 1
	_add_spark(boss_pos, Color("#e6b85c"), 12)


func _boss_barrage(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy.get("pos", WORLD_SIZE * 0.5)
	var count := 10
	for i in range(count):
		var direction := Vector2.RIGHT.rotated(TAU * float(i) / float(count) + randf_range(-0.10, 0.10))
		enemy_projectiles.append({
			"pos": pos + direction * (float(enemy.get("radius", 42.0)) + 8.0),
			"velocity": direction * 205.0,
			"radius": 7.5,
			"damage": _pattern_damage(9.0),
			"life": 4.0,
			"color": Color("#c7b08a"),
		})
	_add_spark(pos, Color("#c7b08a"), 16)


func _update_enemy_emerge(enemy: Dictionary, delta: float) -> bool:
	var timer := float(enemy.get("emerge_timer", 0.0))
	enemy["hit_flash"] = max(0.0, float(enemy.get("hit_flash", 0.0)) - delta * 7.5)
	if timer <= 0.0:
		return false
	enemy["emerge_timer"] = max(0.0, timer - delta)
	return true


func _enemy_is_emerging(enemy: Dictionary) -> bool:
	return float(enemy.get("emerge_timer", 0.0)) > 0.0


func _apply_enemy_separation(delta: float) -> void:
	if enemies.size() < 2:
		return
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		if _enemy_is_emerging(enemy):
			continue
		var pos: Vector2 = enemy["pos"]
		var radius := float(enemy.get("radius", 12.0))
		var separation := Vector2.ZERO
		for j in range(enemies.size()):
			if i == j:
				continue
			var other: Dictionary = enemies[j]
			if float(other.get("hp", 0.0)) <= 0.0:
				continue
			if _enemy_is_emerging(other):
				continue
			var other_pos: Vector2 = other["pos"]
			var desired_distance := radius + float(other.get("radius", 12.0)) + 7.0
			var diff := pos - other_pos
			var distance_sq := diff.length_squared()
			if distance_sq >= desired_distance * desired_distance:
				continue
			var distance := sqrt(max(0.001, distance_sq))
			if distance < 0.25:
				diff = Vector2.RIGHT.rotated(float(enemy.get("id", 0)) * 1.79)
				distance = 1.0
			var pressure := (desired_distance - distance) / desired_distance
			separation += diff / distance * pressure
		if separation.length_squared() <= 0.001:
			continue
		var type := str(enemy.get("type", "zombie"))
		var strength := 72.0
		if _is_boss_type(type):
			strength = 28.0
		elif type == "elite_zombie":
			strength = 44.0
		elif type == "shield_zombie":
			strength = 36.0
		elif type == "spider" or type == "toxic_spider":
			strength = 88.0
		var separated_pos := pos + separation.limit_length(1.0) * strength * delta
		separated_pos.x = clamp(separated_pos.x, -60.0, WORLD_SIZE.x + 60.0)
		separated_pos.y = clamp(separated_pos.y, -60.0, WORLD_SIZE.y + 60.0)
		enemy["pos"] = separated_pos


func _throw_enemy_rock(enemy: Dictionary, direction: Vector2) -> void:
	var origin: Vector2 = enemy["pos"]
	enemy_projectiles.append({
		"pos": origin + direction * (float(enemy["radius"]) + 8.0),
		"velocity": direction * (285.0 + 32.0 * float(_relic_count("sharpened_throwing"))),
		"radius": 7.0,
		"damage": 7.0 + 1.4 * float(_relic_count("sharpened_throwing")),
		"life": 3.0,
		"color": Color("#c7b08a"),
	})
	_add_spark(origin, Color("#c7b08a"), 5)


func _hurt_enemy(enemy: Dictionary, damage: float, hit_pos: Vector2, armor_pierce: float = 0.0, push_direction: Vector2 = Vector2.ZERO, feedback: String = "hit") -> void:
	debug_hurt_events += 1
	var hp_before := float(enemy.get("hp", 0.0))
	if str(enemy.get("type", "")) == "shield_zombie" and _shield_blocks_hit(enemy, push_direction, armor_pierce, feedback):
		damage *= _shield_front_damage_multiplier()
		feedback = "armor"
	var effective_armor = max(0.0, float(enemy.get("armor", 0.0)) - armor_pierce)
	var final_damage = max(1.0, damage - effective_armor)
	enemy["hp"] = hp_before - final_damage
	if _is_boss_type(str(enemy.get("type", ""))):
		run_boss_damage += min(final_damage, max(0.0, hp_before))
	var feedback_color := _hit_feedback_color(feedback)
	enemy["hit_flash"] = 1.0
	enemy["hit_flash_color"] = feedback_color
	_apply_enemy_knockback(enemy, push_direction, _hit_knockback_amount(feedback) + float(enemy.get("bonus_knockback", 0.0)))
	var text_pos := hit_pos + Vector2(0, -8)
	if feedback == "armor":
		text_pos += Vector2(0, -18)
	_add_floating_text(_hit_feedback_text(final_damage, feedback), text_pos, feedback_color)
	_add_hit_feedback_sparks(hit_pos, push_direction, feedback_color, feedback)


func _shield_blocks_hit(enemy: Dictionary, push_direction: Vector2, armor_pierce: float, feedback: String) -> bool:
	if armor_pierce >= 2.5 or feedback == "splash" or feedback == "splash_direct" or feedback == "pierce":
		return false
	var front: Vector2 = (Vector2(player.get("pos", Vector2.ZERO)) - Vector2(enemy.get("pos", Vector2.ZERO))).normalized()
	var incoming := push_direction.normalized()
	if incoming.length_squared() <= 0.001:
		return true
	return incoming.dot(front) > 0.38


func _shield_front_damage_multiplier() -> float:
	return max(0.22, 0.42 - 0.08 * float(_relic_count("cracked_shield_oath")))


func _weapon_has_mod(weapon: Dictionary, mod_name: String) -> bool:
	var mods: Array = weapon.get("mods", [])
	return mods.has(mod_name)


func _add_muzzle_feedback(origin: Vector2, direction: Vector2, weapon: Dictionary, rapid_feedback: bool) -> void:
	var color: Color = weapon.get("color", Color("#f5efe3"))
	var spark_count := 6
	if rapid_feedback:
		spark_count = 11
		_add_line_spark(origin - direction * 7.0, origin + direction * 28.0, Color("#f2cf66"), 0.10, 3.5)
	if int(weapon.get("pierce", 0)) > 0:
		_add_line_spark(origin + direction * 4.0, origin + direction * 36.0, Color("#6cc3c0"), 0.12, 2.5)
	if float(weapon.get("splash", 0.0)) > 0.0:
		_add_line_spark(origin + direction * 6.0, origin + direction * 24.0, Color("#f0643b"), 0.10, 4.0)
	if float(weapon.get("armor_pierce", 0.0)) > 0.0:
		_add_line_spark(origin + direction * 8.0, origin + direction * 32.0, Color("#d8f3ff"), 0.13, 2.0)
	_add_directional_sparks(origin, direction, color, spark_count)


func _bullet_hit_feedback(bullet: Dictionary, enemy: Dictionary, from_splash: bool, direct_hit: bool) -> String:
	if float(bullet.get("armor_pierce", 0.0)) > 0.0 and float(enemy.get("armor", 0.0)) > 0.0:
		return "armor"
	if from_splash:
		return "splash_direct" if direct_hit else "splash"
	if bool(bullet.get("pierce_feedback", false)):
		return "pierce"
	return "hit"


func _splash_feedback_color(bullet: Dictionary) -> Color:
	if bool(bullet.get("armor_feedback", false)):
		return Color("#d8f3ff")
	return Color("#f0643b")


func _hit_feedback_color(feedback: String) -> Color:
	match feedback:
		"armor":
			return Color("#d8f3ff")
		"pierce":
			return Color("#6cc3c0")
		"splash", "splash_direct":
			return Color("#f0643b")
		"arc":
			return Color("#6cc3c0")
		"lantern":
			return Color("#e6b85c")
		"slash":
			return Color("#f2cf66")
		_:
			return Color("#f5efe3")


func _hit_feedback_text(damage: float, feedback: String) -> String:
	var amount := int(round(damage))
	match feedback:
		"armor":
			return "방관 %d" % amount
		"pierce":
			return "관통 %d" % amount
		"splash_direct":
			return "직격 %d" % amount
		"splash":
			return "폭발 %d" % amount
		"lantern":
			return "빛 %d" % amount
		_:
			return str(amount)


func _hit_knockback_amount(feedback: String) -> float:
	match feedback:
		"armor":
			return 58.0
		"pierce":
			return 48.0
		"splash_direct":
			return 44.0
		"splash":
			return 32.0
		"arc":
			return 26.0
		"lantern":
			return 22.0
		"slash":
			return 38.0
		_:
			return 34.0


func _apply_enemy_knockback(enemy: Dictionary, direction: Vector2, amount: float) -> void:
	if direction.length_squared() <= 0.001:
		direction = (Vector2(enemy.get("pos", Vector2.ZERO)) - Vector2(player.get("pos", Vector2.ZERO))).normalized()
	if direction.length_squared() <= 0.001:
		return
	var type := str(enemy.get("type", "zombie"))
	var multiplier := 1.0
	match type:
		"spider":
			multiplier = 1.25
		"toxic_spider":
			multiplier = 1.20
		"bomb_miner":
			multiplier = 0.95
		"thrower":
			multiplier = 0.85
		"shield_zombie":
			multiplier = 0.32
		"elite_zombie":
			multiplier = 0.45
		"boss", "mid_boss", "final_boss":
			multiplier = 0.24
	var velocity: Vector2 = enemy.get("knockback_velocity", Vector2.ZERO)
	enemy["knockback_velocity"] = (velocity + direction.normalized() * amount * multiplier).limit_length(180.0)


func _add_hit_feedback_sparks(pos: Vector2, direction: Vector2, color: Color, feedback: String) -> void:
	var count := 7
	var size := 3.0
	match feedback:
		"armor":
			count = 14
			size = 3.6
			_add_line_spark(pos - direction.normalized() * 12.0, pos + direction.normalized() * 18.0, color, 0.14, 3.0)
		"pierce":
			count = 11
			size = 3.2
			_add_line_spark(pos - direction.normalized() * 24.0, pos + direction.normalized() * 20.0, color, 0.12, 2.4)
		"splash", "splash_direct":
			count = 12
			size = 4.0
	_add_directional_sparks(pos, direction, color, count, size)


func _add_directional_sparks(pos: Vector2, direction: Vector2, color: Color, count: int, size: float = 3.0) -> void:
	var base_direction := direction.normalized()
	if base_direction.length_squared() <= 0.001:
		base_direction = Vector2.RIGHT.rotated(randf() * TAU)
	for i in range(count):
		var angle := randf_range(-0.95, 0.95)
		var speed := randf_range(70.0, 240.0)
		sparks.append({
			"line": false,
			"pos": pos,
			"velocity": base_direction.rotated(angle) * speed,
			"life": randf_range(0.12, 0.28),
			"max_life": 0.28,
			"color": color,
			"size": size,
		})


func _add_line_spark(from: Vector2, to: Vector2, color: Color, life: float = 0.12, width: float = 3.0) -> void:
	sparks.append({
		"line": true,
		"from": from,
		"to": to,
		"life": life,
		"max_life": life,
		"color": color,
		"width": width,
	})


func _drop_pickups(enemy: Dictionary) -> void:
	if not P2_SHOP_REWARDS_ENABLED:
		return
	if P2_LEVEL_UP_REWARDS_ENABLED and float(enemy["xp"]) > 0.0:
		pickups.append({"pos": enemy["pos"], "radius": 8.0, "type": "xp", "value": enemy["xp"], "color": Color("#6cc3c0")})
	if not EconomyRulesScript.currency_drops_enabled(wave):
		return
	var profile: Dictionary = enemy.get("currency_drop", {})
	if not bool(profile.get("drops_enabled", true)):
		return
	var preferred_currency_id := str(profile.get("primary_currency_id", ""))
	var contract_multiplier := _contract_currency_multiplier(enemy, preferred_currency_id)
	var outcome := EconomyRulesScript.currency_drop_outcome(profile, randf(), contract_multiplier)
	if outcome.is_empty():
		return
	var currency_id := str(outcome.get("currency_id", ""))
	var definition := _currency_definition(currency_id)
	if definition.is_empty():
		push_error("CURRENCY_DROP_REJECTED reason=unknown_currency enemy=%s profile=%s" % [str(enemy.get("type", "")), JSON.stringify(profile)])
		return
	var scaled_amount := float(outcome.get("amount", 0)) * currency_drop_multiplier
	if not profile.has("drop_weights"):
		scaled_amount *= contract_multiplier
	var drop_count := int(floor(scaled_amount))
	if randf() < scaled_amount - float(drop_count):
		drop_count += 1
	for i in range(drop_count):
		pickups.append({
			"pos": enemy["pos"] + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
			"radius": 6.0,
			"type": "currency",
			"currency_id": currency_id,
			"value": 1,
			"color": Color(str(definition.get("color", "#f5efe3"))),
			"shape": str(definition.get("shape", "diamond")),
		})


func _update_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var item = pickups[i]
		var to_player: Vector2 = player["pos"] - item["pos"]
		var distance: float = max(1.0, to_player.length())
		if distance < player["pickup_range"]:
			var pull: float = 1.0 - distance / player["pickup_range"]
			item["pos"] += to_player.normalized() * (180.0 + pull * 520.0) * delta

		if distance < player["radius"] + item["radius"]:
			if item["type"] == "currency":
				var value := int(item.get("value", 0))
				var currency_id := str(item.get("currency_id", ""))
				if _credit_currency(currency_id, value):
					var definition := _currency_definition(currency_id)
					_add_floating_text("+%d %s" % [value, str(definition.get("name", currency_id))], item["pos"], Color(str(definition.get("color", "#f5efe3"))))
			elif item["type"] == "xp":
				_add_xp(item["value"] * xp_multiplier)
			else:
				push_error("PICKUP_REJECTED reason=unknown_type pickup=%s" % JSON.stringify(item))
			pickups.remove_at(i)


func _add_xp(amount: float) -> void:
	if not P2_LEVEL_UP_REWARDS_ENABLED:
		return
	xp += amount
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = floor(xp_to_next * 1.32 + 9.0)
		_open_level_up()


func _update_sparks(delta: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var spark = sparks[i]
		if not spark.get("line", false):
			spark["pos"] += spark["velocity"] * delta
		spark["life"] -= delta
		if spark["life"] <= 0.0:
			sparks.remove_at(i)


func _update_floating_text(delta: float) -> void:
	for i in range(floating_text.size() - 1, -1, -1):
		var text = floating_text[i]
		var pos: Vector2 = text["pos"]
		pos.y -= 38.0 * delta
		text["pos"] = pos
		text["life"] -= delta
		if text["life"] <= 0.0:
			floating_text.remove_at(i)


func _can_add_weapon(id: String) -> bool:
	for weapon in weapons:
		if weapon["id"] == id:
			return int(weapon["level"]) < MAX_WEAPON_LEVEL
	return weapons.size() < MAX_WEAPON_SLOTS


func _add_weapon(id: String) -> bool:
	if not weapon_catalog.has(id):
		return false
	for weapon in weapons:
		if weapon["id"] == id:
			if int(weapon["level"]) >= MAX_WEAPON_LEVEL:
				return false
			weapon["level"] += 1
			weapon["damage"] *= 1.22
			weapon["cooldown"] *= 0.92
			weapon["range"] *= 1.04
			return true

	if weapons.size() >= MAX_WEAPON_SLOTS:
		return false

	var template: Dictionary = weapon_catalog[id]
	weapons.append({
		"id": id,
		"name": template["name"],
		"family": template.get("family", ""),
		"feel": template.get("feel", ""),
		"icon": template.get("icon", ""),
		"fire_type": template["fire_type"],
		"level": 1,
		"upgrade_rank": 0,
		"cooldown": template["cooldown"],
		"timer": randf() * 0.25,
		"damage": template["damage"],
		"range": template["range"],
		"speed": template["speed"],
		"pierce": template["pierce"],
		"projectiles": template["projectiles"],
		"spread": template["spread"],
		"splash": template["splash"],
		"armor_pierce": template.get("armor_pierce", 0.0),
		"knockback": template.get("knockback", 0.0),
		"shape": template.get("shape", "round"),
		"mods": [],
		"color": template["color"],
	})
	return true


func _equip_weapon_for_run(id: String) -> bool:
	weapons.clear()
	if not _add_weapon(id):
		return false
	selected_weapon_id = id
	_render_weapons()
	return true


func _starter_weapon_options() -> Array:
	var options: Array = []
	for id in starter_weapon_ids:
		var weapon: Dictionary = weapon_catalog[id]
		options.append({
			"id": id,
			"kind": "starter_weapon",
			"name": str(weapon.get("name", "")),
			"desc": "%s\n강점: %s\n약점: %s" % [
				str(weapon.get("feel", "")),
				str(weapon.get("strength", "")),
				str(weapon.get("weakness", "")),
			],
			"tag": "%s 계열" % str(weapon.get("family", "")),
			"icon": str(weapon.get("icon", "")),
			"cost": 0,
		})
	return options


func _add_spark(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var angle := randf() * TAU
		var speed := randf_range(40.0, 190.0)
		sparks.append({
			"line": false,
			"pos": pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.18, 0.36),
			"max_life": 0.36,
			"color": color,
		})


func _add_floating_text(text: String, pos: Vector2, color: Color) -> void:
	floating_text.append({"text": text, "pos": pos, "color": color, "life": 0.55})


func _open_level_up() -> void:
	mode = MODE_CHOICE
	_show_choice_overlay("레벨 %d" % level, "보상 선택", _sample_array(_stat_rewards_for_selected_weapon(), 3), "_choose_reward")


func _stat_rewards_for_selected_weapon() -> Array:
	var decorated: Array = []
	var decorations := _weapon_stat_reward_decorations(_current_weapon_id())
	for reward in stat_rewards:
		var option: Dictionary = reward.duplicate(true)
		var id := str(option.get("id", ""))
		if decorations.has(id):
			var copy: Dictionary = decorations[id]
			option["name"] = str(copy.get("name", option.get("name", "")))
			option["desc"] = str(copy.get("desc", option.get("desc", "")))
		decorated.append(option)
	return decorated


func _weapon_stat_reward_decorations(weapon_id: String) -> Dictionary:
	match weapon_id:
		"pickaxe":
			return {
				"cooldown": {"name": "휘두름 리듬 조정", "desc": "곡괭이 휘두름 간격이 아주 소폭 줄어듭니다."},
				"damage": {"name": "곡괭이날 연마", "desc": "곡괭이 한 번의 피해량이 아주 소폭 증가합니다."},
				"range": {"name": "긴 곡괭이 자루", "desc": "곡괭이 휘두름 범위가 아주 소폭 증가합니다."},
			}
		"nailgun":
			return {
				"cooldown": {"name": "방아쇠 리듬 조정", "desc": "네일건 발사 간격이 아주 소폭 줄어듭니다."},
				"damage": {"name": "강화 강철 못", "desc": "못 한 발의 피해량이 아주 소폭 증가합니다."},
				"range": {"name": "긴 압축 레일", "desc": "못 비행 거리가 아주 소폭 증가합니다."},
			}
		"lantern":
			return {
				"cooldown": {"name": "심지 리듬 조정", "desc": "랜턴 빛 펄스 간격이 아주 소폭 줄어듭니다."},
				"damage": {"name": "밝은 심지", "desc": "빛 펄스 피해량이 아주 소폭 증가합니다."},
				"range": {"name": "확산 렌즈", "desc": "빛 펄스 반경이 아주 소폭 증가합니다."},
			}
	return {}


func _choose_reward(reward: Dictionary) -> void:
	match reward["id"]:
		"hp":
			player["max_hp"] += 10.0
			player["hp"] = min(player["max_hp"], player["hp"] + 14.0)
		"speed":
			player["speed"] *= 1.045
		"range":
			range_multiplier *= 1.055
		"damage":
			damage_multiplier *= 1.055
		"cooldown":
			cooldown_multiplier *= 0.955
		"armor":
			player["armor"] += 0.45
		"regen":
			hp_regen += 0.10
	_hide_overlay()
	_render_weapons()
	_open_next_reward_or_round()


func _finish_round() -> void:
	if mode != MODE_PLAY:
		return
	_set_paused(false)
	rounds_cleared += 1
	_collect_leftover_currency()
	_award_round_clear_currency()
	_clear_combat_state()
	spawn_timer = 0.0
	screen_shake = 0.0
	_set_run_rule_state(RunRulesScript.advance_checkpoint_state(run_rule_state, wave + 1))

	pending_reward_chain = _reward_chain_for_round(wave)
	_open_next_reward_or_round()


func _reward_chain_for_round(round_index: int) -> Array:
	return RunRulesScript.reward_chain_for_round(round_index)


func _reward_route_label(round_index: int) -> String:
	var labels := PackedStringArray()
	for step in _reward_chain_for_round(round_index):
		match str(step.get("type", "")):
			"stat":
				labels.append("stat")
			"contract":
				labels.append("contract")
			"checkpoint":
				labels.append("checkpoint")
			"shop":
				labels.append("shop")
			"final_shop":
				labels.append("final_shop")
	return " -> ".join(labels) if not labels.is_empty() else "victory"


func _open_next_reward_or_round() -> void:
	if pending_reward_chain.is_empty():
		_start_next_round()
		return
	active_reward_context = pending_reward_chain.pop_front()
	match str(active_reward_context.get("type", "")):
		"stat":
			_open_stat_reward()
		"contract":
			_open_contract_choice()
		"checkpoint":
			_open_checkpoint_choice()
		"shop", "final_shop":
			_open_shop()
		_:
			_open_next_reward_or_round()


func _collect_leftover_currency() -> void:
	for item in pickups:
		if item["type"] == "currency":
			var value := int(item.get("value", 0))
			_credit_currency(str(item.get("currency_id", "")), value)
	pickups.clear()


func _award_round_clear_currency() -> void:
	var base_reward := EconomyRulesScript.round_clear_reward(wave)
	var reward := int(round(float(base_reward) * _relic_clear_currency_multiplier()))
	if reward > 0 and _credit_currency("ore", reward):
		run_round_clear_ore += reward


func _clear_combat_state() -> void:
	enemies.clear()
	bullets.clear()
	enemy_projectiles.clear()
	pickups.clear()
	spawn_warnings.clear()
	hazard_zones.clear()


func _fully_heal_player() -> void:
	player["hp"] = player["max_hp"]
	player["hurt_cooldown"] = 0.0


func _open_round_break() -> void:
	mode = MODE_CHOICE
	var next_wave := wave + 1
	_show_choice_overlay(
		"라운드 %d 완료" % wave,
		"체력 완전 회복",
		[{
			"id": "next_round",
			"kind": "command",
			"name": "라운드 %d 시작" % next_wave,
			"desc": _round_brief(next_wave),
			"cost": 0,
		}],
		"_choose_round_break_option"
	)


func _choose_round_break_option(option: Dictionary) -> void:
	if str(option.get("id", "")) == "next_round":
		_start_next_round()


func _round_brief(round_index: int) -> String:
	return DemoContentScript.round_brief(round_index)


func _next_round_warning_text(round_index: int) -> String:
	return DemoContentScript.next_round_warning_text(round_index)


func _reward_eyebrow_text() -> String:
	return "라운드 %d 완료  ·  %s  ·  %s" % [wave, _round_currency_summary(), _next_round_warning_text(min(wave + 1, MAX_ROUNDS))]


func _next_reward_or_round_desc() -> String:
	if not pending_reward_chain.is_empty():
		var next_type := str(Dictionary(pending_reward_chain[0]).get("type", ""))
		match next_type:
			"stat":
				return "다음 보상으로 기본 체급 보정을 선택합니다."
			"contract":
				return "다음 보상으로 위험한 광맥 계약을 선택합니다."
			"checkpoint":
				return "다음 구간의 안전, 위험, 상점, 엘리트 경로를 선택합니다."
			"shop", "final_shop":
				return "다음 보상으로 상점에 진입합니다."
	return "%s\n%s" % [_next_round_warning_text(min(wave + 1, MAX_ROUNDS)), _round_brief(min(wave + 1, MAX_ROUNDS))]


func _open_relic_choice() -> void:
	mode = MODE_CHOICE
	var options := _roll_relic_options()
	_show_choice_overlay("라운드 %d 완료  ·  %s" % [wave, _round_currency_summary()], "계약 선택", options, "_choose_relic_option")


func _choose_relic_option(relic: Dictionary) -> void:
	if str(relic.get("kind", "")) != "relic":
		return
	_add_relic(relic)
	_open_next_reward_or_round()


func _choose_checkpoint_risk_relic(relic: Dictionary) -> void:
	if str(relic.get("kind", "")) != "relic":
		return
	_add_relic(relic)
	_set_run_rule_state(RunRulesScript.attach_persistent_risk(run_rule_state, str(relic.get("id", ""))))
	_open_next_reward_or_round()


func _open_stat_reward() -> void:
	mode = MODE_CHOICE
	var title := "기본 체급 보정"
	var eyebrow := _reward_eyebrow_text()
	_show_choice_overlay(eyebrow, title, _sample_array(_stat_rewards_for_selected_weapon(), 3), "_choose_reward")


func _open_contract_choice(choice_method: String = "_choose_relic_option") -> void:
	mode = MODE_CHOICE
	var options := _roll_relic_options()
	_show_choice_overlay("계약 이벤트  ·  %s" % _next_round_warning_text(min(wave + 1, MAX_ROUNDS)), "위험한 광맥 선택", options, choice_method)


func _open_checkpoint_choice() -> void:
	var locked_checkpoint_round := int(run_rule_state.get("checkpoint_round", 0))
	var locked_route := str(run_rule_state.get("selected_route", ""))
	if not locked_route.is_empty() and locked_checkpoint_round == wave:
		_hide_overlay()
		active_choice_options.clear()
		active_choice_method = ""
		if wave <= locked_checkpoint_round:
			print("CHECKPOINT_REENTRY_FAILSAFE action=advance checkpoint_round=%d wave=%d route=%s state=%s" % [locked_checkpoint_round, wave, locked_route, JSON.stringify(run_rule_state)])
			_open_next_reward_or_round()
		else:
			print("CHECKPOINT_REENTRY_FAILSAFE action=preserve checkpoint_round=%d wave=%d route=%s state=%s" % [locked_checkpoint_round, wave, locked_route, JSON.stringify(run_rule_state)])
			mode = MODE_PLAY
		return
	if not RunRulesScript.is_checkpoint_round(wave):
		print("CHECKPOINT_ROUTE_ERROR reason=checkpoint_not_scheduled wave=%d state=%s" % [wave, JSON.stringify(run_rule_state)])
		_hide_overlay()
		active_choice_options.clear()
		active_choice_method = ""
		mode = MODE_PLAY
		return
	mode = MODE_CHOICE
	_set_run_rule_state(RunRulesScript.open_checkpoint(run_rule_state, wave))
	_show_choice_overlay(
		"R%d 완료 · 다음 구간을 직접 선택" % wave,
		"얼마나 깊이 들어갈까요?",
		DemoContentScript.checkpoint_route_options(wave),
		"_choose_checkpoint_route"
	)


func _choose_checkpoint_route(option: Dictionary) -> void:
	var route_id := str(option.get("id", ""))
	if str(option.get("kind", "")) != "checkpoint_route" or not RunRulesScript.is_checkpoint_route(route_id):
		print("CHECKPOINT_ROUTE_ERROR reason=unknown_or_missing state=%s option=%s" % [JSON.stringify(run_rule_state), JSON.stringify(option)])
		return
	var offered := _active_choice_option_by_id(route_id)
	if offered.is_empty() or _choice_option_disabled(offered):
		print("CHECKPOINT_ROUTE_ERROR reason=disabled_or_unoffered state=%s option=%s" % [JSON.stringify(run_rule_state), JSON.stringify(option)])
		return
	var result: Dictionary = RunRulesScript.select_checkpoint_route(run_rule_state, route_id)
	if not bool(result.get("ok", false)):
		print("CHECKPOINT_ROUTE_ERROR reason=%s state=%s option=%s" % [str(result.get("error", "unknown")), JSON.stringify(run_rule_state), JSON.stringify(option)])
		return
	_set_run_rule_state(result.get("state", run_rule_state))
	_hide_overlay()
	match route_id:
		"safe":
			_fully_heal_player()
			_open_next_reward_or_round()
		"risk":
			_open_contract_choice("_choose_checkpoint_risk_relic")
		"shop":
			_open_shop()
		"elite":
			_open_next_reward_or_round()


func _roll_relic_options() -> Array:
	var rolled: Array = []
	var repeat := _next_contract_repeat_candidate()
	if not repeat.is_empty():
		rolled.append(repeat)

	var candidates := _contract_candidates_for_round(wave)
	candidates.shuffle()
	candidates.sort_custom(func(a, b): return _relic_seen_count(a) < _relic_seen_count(b))
	for relic in candidates:
		if rolled.size() >= RELIC_OPTION_COUNT:
			break
		var id := str(relic.get("id", ""))
		if _relic_count(id) >= 3:
			continue
		if _stock_has_item_id(rolled, id):
			continue
		rolled.append(relic.duplicate(true))
	_record_relic_seen(rolled)
	return rolled


func _contract_candidates_for_round(round_index: int) -> Array:
	var candidates: Array = []
	for id in DemoContentScript.contract_ids_for_round(round_index):
		var relic := _relic_by_id(id)
		if not relic.is_empty():
			candidates.append(relic)
	return candidates


func _next_contract_repeat_candidate() -> Dictionary:
	if wave < 5:
		return {}
	for relic in active_relics:
		var id := str(relic.get("id", ""))
		if _relic_count(id) <= 0 or _relic_count(id) >= 3:
			continue
		var candidates := _contract_candidates_for_round(wave)
		for candidate in candidates:
			if str(candidate.get("id", "")) == id:
				return candidate.duplicate(true)
	return {}


func _add_relic(relic: Dictionary) -> void:
	if relic.is_empty():
		return
	var id := str(relic.get("id", ""))
	if id.is_empty():
		return
	if _relic_count(id) >= 3:
		return
	active_relics.append(relic.duplicate(true))
	relic_counts[id] = _relic_count(id) + 1


func _open_shop() -> void:
	mode = MODE_CHOICE
	shop_visit_seen_item_ids.clear()
	reroll_cost = _shop_reroll_cost()
	shop_stock = _roll_shop_stock()
	_show_shop_overlay()


func _show_shop_overlay() -> void:
	var options := _decorate_shop_options_for_selected_weapon(shop_stock)
	options.append(_weapon_temper_option())
	options.append({"id": "reroll", "kind": "command", "name": "재고 새로고침", "desc": "상점 선택지를 다시 뽑습니다.", "cost": _typed_cost("catalyst", reroll_cost)})
	var next_text := "다음 보상" if not pending_reward_chain.is_empty() else "다음 라운드"
	options.append({"id": "next_round", "kind": "command", "name": next_text, "desc": _next_reward_or_round_desc(), "cost": _typed_cost("ore", 0)})
	var title := "최종 준비 상점 · %s" % _wallet_balance_summary() if str(active_reward_context.get("type", "")) == "final_shop" else "상점 · %s" % _wallet_balance_summary()
	_show_choice_overlay(_reward_eyebrow_text(), title, options, "_choose_shop_option")


func _weapon_temper_option() -> Dictionary:
	var target := _current_upgrade_target()
	if target.is_empty():
		return {
			"id": "temper_weapon", "kind": "temper", "name": "장비 단련",
			"desc": "선택한 스타터 무기를 찾을 수 없어 단련할 수 없습니다.",
			"cost": _typed_cost("forge_core", 1), "disabled": true, "disabled_reason": "단련 대상 없음",
		}
	var weapon_id := str(target.get("id", ""))
	var recipe := DemoContentScript.weapon_temper_recipe(weapon_id)
	var rank := int(target.get("upgrade_rank", 0))
	var max_rank := int(recipe.get("max_rank", 3))
	var cost := _typed_cost("forge_core", 1 + rank)
	return {
		"id": "temper_weapon", "kind": "temper", "name": str(recipe.get("name", "장비 단련")),
		"desc": "%s 현재 %s → %s" % [str(recipe.get("description", "무기를 단련합니다.")), _roman_rank(rank), _roman_rank(min(rank + 1, max_rank))],
		"cost": cost,
		"disabled": rank >= max_rank,
		"disabled_reason": "단련 한도 III" if rank >= max_rank else "",
		"weapon_id": weapon_id,
		"rank": rank,
	}


func _decorate_shop_options_for_selected_weapon(options: Array) -> Array:
	var decorated: Array = []
	for option in options:
		decorated.append(_decorate_shop_option_for_selected_weapon(option))
	return decorated


func _decorate_shop_option_for_selected_weapon(option: Dictionary) -> Dictionary:
	var copy := option.duplicate(true)
	if str(copy.get("kind", "")) != "part":
		return copy
	var weapon_id := _current_weapon_id()
	if weapon_id.is_empty():
		return copy
	var decorations := _weapon_shop_decorations(weapon_id)
	var item_id := str(copy.get("id", ""))
	if decorations.has(item_id):
		var decoration: Dictionary = decorations[item_id]
		copy["name"] = str(decoration.get("name", copy.get("name", "")))
		copy["desc"] = str(decoration.get("desc", copy.get("desc", "")))
		copy["counter"] = str(decoration.get("counter", copy.get("counter", "")))
		copy["icon"] = _current_weapon_icon()
	return copy


func _weapon_shop_decorations(weapon_id: String) -> Dictionary:
	match weapon_id:
		"pickaxe":
			return {
				"lubricated_bearing": {"name": "손목 축 윤활", "desc": "곡괭이 휘두름 쿨다운이 줄어듭니다. 짧은 딜타임을 더 자주 엽니다.", "counter": "근접 회전율"},
				"extended_shaft": {"name": "긴 곡괭이 자루", "desc": "휘두름 사거리 소폭 증가. 방패와 폭약 앞에서 반 걸음 여유를 만듭니다.", "counter": "근접 거리"},
				"reinforced_bit": {"name": "강화 곡괭이날", "desc": "곡괭이 피해량 소폭 증가. 보스와 단단한 적을 더 빨리 깎습니다.", "counter": "근접 피해"},
				"piercing_bit": {"name": "쐐기 곡괭이날", "desc": "휘두름의 관통 판정이 강해집니다. 방패 라인 측면과 뭉친 적을 찢습니다.", "counter": "측면 돌파"},
				"explosive_core": {"name": "충격 폭약 머리", "desc": "곡괭이 명중 지점에 작은 폭발을 붙입니다. 붙은 무리를 한 번에 흔듭니다.", "counter": "근접 광역"},
				"armor_shredding_blade": {"name": "장갑 파쇄 곡괭이", "desc": "방어 관통 +3. 방패 좀비와 보스의 단단한 표면을 더 잘 깹니다.", "counter": "방어 관통"},
				"recoil_spring": {"name": "반동 손잡이", "desc": "휘두름 넉백 강화. 붙은 적과 자폭 광부를 한 박자 밀어냅니다.", "counter": "접근 차단"},
				"double_drill_chamber": {"name": "쌍날 곡괭이 머리", "desc": "보조 휘두름을 추가합니다. 피해는 조금 보정되지만 타격 횟수가 늘어납니다.", "counter": "타격 횟수 +1"},
			}
		"nailgun":
			return {
				"lubricated_bearing": {"name": "급속 못 방아쇠", "desc": "네일건 발사 간격이 줄어듭니다. 빠른 적을 더 빨리 끊습니다.", "counter": "원거리 연사"},
				"extended_shaft": {"name": "긴 압축 레일", "desc": "못 사거리와 탄속이 소폭 증가합니다. 투척 적을 먼저 찌릅니다.", "counter": "거리 확보"},
				"reinforced_bit": {"name": "강화 강철 못", "desc": "못 피해량 소폭 증가. 단일 대상을 안정적으로 정리합니다.", "counter": "직선 피해"},
				"piercing_bit": {"name": "관통 못 탄창", "desc": "못 관통 +1. 방패 라인 뒤쪽과 일렬 적을 노립니다.", "counter": "직선 관통"},
				"explosive_core": {"name": "폭약 못심", "desc": "못 명중 지점에 작은 폭발을 붙입니다. 부족한 무리 대응을 보완합니다.", "counter": "밀집 적 대응"},
				"armor_shredding_blade": {"name": "장갑 파쇄 못", "desc": "방어 관통 +3. 방패 정면과 보스 방어를 더 잘 뚫습니다.", "counter": "방어 관통"},
				"recoil_spring": {"name": "고압 반동 스프링", "desc": "넉백 강화와 탄속 증가. 돌진 위협을 거리 밖으로 밀어냅니다.", "counter": "돌진 대응"},
				"double_drill_chamber": {"name": "쌍열 못 탄창", "desc": "못 한 발을 추가로 발사합니다. 피해는 조금 보정되지만 공격 레인이 늘어납니다.", "counter": "못 한 발 +1"},
			}
		"lantern":
			return {
				"lubricated_bearing": {"name": "빠른 심지 조절기", "desc": "랜턴 펄스 쿨다운이 줄어듭니다. 주변 압박을 더 자주 비웁니다.", "counter": "펄스 회전율"},
				"extended_shaft": {"name": "확산 렌즈", "desc": "빛 펄스 반경이 소폭 증가합니다. 동선을 더 넓게 확보합니다.", "counter": "영역 확보"},
				"reinforced_bit": {"name": "밝은 심지", "desc": "빛 펄스 피해량 소폭 증가. 몰려든 적을 더 안정적으로 태웁니다.", "counter": "영역 피해"},
				"piercing_bit": {"name": "집중 렌즈", "desc": "빛이 방어 틈을 파고듭니다. 방패 라인과 밀집 적 대응을 보완합니다.", "counter": "빛 관통"},
				"explosive_core": {"name": "불꽃 기름통", "desc": "펄스 명중 지점에 작은 불꽃 폭발을 붙입니다. 뭉친 적에게 강해집니다.", "counter": "밀집 적 대응"},
				"armor_shredding_blade": {"name": "백열 렌즈", "desc": "방어 관통 +3. 단단한 적에게 빛 피해가 더 잘 들어갑니다.", "counter": "방어 관통"},
				"recoil_spring": {"name": "파동 반사판", "desc": "펄스 넉백이 강해집니다. 주변으로 붙은 적을 밀어냅니다.", "counter": "접근 차단"},
				"double_drill_chamber": {"name": "쌍심지 랜턴", "desc": "두 번째 빛 고리를 추가합니다. 피해는 조금 보정되지만 펄스 횟수가 늘어납니다.", "counter": "펄스 +1"},
			}
	return {}


func _roll_shop_stock(avoid_ids: Array = []) -> Array:
	var rolled: Array = []
	var next_round: int = min(wave + 1, MAX_ROUNDS)
	var counter_pool: Array = _shop_items_for_round(next_round, avoid_ids)
	if not counter_pool.is_empty():
		var counter := _least_seen_shop_item(counter_pool).duplicate(true)
		if randf() < _shop_rarity_weight(str(counter.get("rarity", "common")), next_round) + 0.18:
			rolled.append(counter)

	while rolled.size() < SHOP_OPTION_COUNT:
		var rarity := _roll_shop_rarity(next_round)
		var candidates: Array = _available_shop_items_by_rarity(rarity, avoid_ids)
		if candidates.is_empty() and rarity == "legendary":
			candidates = _available_shop_items_by_rarity("rare", avoid_ids)
		if candidates.is_empty():
			candidates = _available_shop_items(avoid_ids)
		candidates.shuffle()
		candidates.sort_custom(func(a, b): return _shop_seen_count(a) < _shop_seen_count(b))
		var added := false
		for option in candidates:
			if _stock_has_item_id(rolled, str(option.get("id", ""))):
				continue
			rolled.append(option.duplicate(true))
			added = true
			break
		if not added:
			break

	for i in range(rolled.size()):
		var option: Dictionary = rolled[i]
		option["stock_id"] = "%s_%d_%d_%d" % [option["id"], wave, rounds_cleared, i]
		option["cost"] = _typed_cost("ore", _scaled_shop_cost(int(option["cost"]), str(option.get("rarity", "common"))))
	_record_shop_seen(rolled)
	_record_shop_visit_seen(rolled)
	return rolled


func _roll_shop_rarity(round_index: int) -> String:
	var common_weight := _shop_rarity_weight("common", round_index)
	var rare_weight := _shop_rarity_weight("rare", round_index)
	var legendary_weight := _shop_rarity_weight("legendary", round_index)
	var total := common_weight + rare_weight + legendary_weight
	var roll := randf() * total
	if roll < legendary_weight:
		return "legendary"
	if roll < legendary_weight + rare_weight:
		return "rare"
	return "common"


func _shop_rarity_weight(rarity: String, round_index: int) -> float:
	return EconomyRulesScript.shop_rarity_weight(rarity, round_index)


func _shop_items_for_round(round_index: int, avoid_ids: Array = []) -> Array:
	var pool: Array = []
	for option in shop_catalog:
		if _shop_item_can_appear(option, avoid_ids) and option.has("counters") and option["counters"].has(round_index):
			pool.append(option)
	return pool


func _available_shop_items(avoid_ids: Array) -> Array:
	var pool: Array = []
	for option in shop_catalog:
		if _shop_item_can_appear(option, avoid_ids):
			pool.append(option)
	return pool


func _available_shop_items_by_rarity(rarity: String, avoid_ids: Array) -> Array:
	var pool: Array = []
	for option in shop_catalog:
		if str(option.get("rarity", "common")) == rarity and _shop_item_can_appear(option, avoid_ids):
			pool.append(option)
	return pool


func _shop_item_by_id(id: String) -> Dictionary:
	for option in shop_catalog:
		if str(option.get("id", "")) == id:
			return option
	return {}


func _shop_item_can_appear(option: Dictionary, avoid_ids: Array) -> bool:
	var id := str(option.get("id", ""))
	if avoid_ids.has(id):
		return false
	if bool(option.get("unique", false)) and purchased_shop_item_ids.has(id):
		return false
	return true


func _current_shop_item_ids() -> Array:
	var ids: Array = []
	for option in shop_stock:
		ids.append(str(option.get("id", "")))
	return ids


func _least_seen_shop_item(pool: Array) -> Dictionary:
	var candidates: Array = pool.duplicate(true)
	candidates.shuffle()
	candidates.sort_custom(func(a, b): return _shop_seen_count(a) < _shop_seen_count(b))
	return candidates[0]


func _shop_seen_count(option: Dictionary) -> int:
	return int(shop_seen_counts.get(str(option.get("id", "")), 0))


func _record_shop_seen(stock: Array) -> void:
	for option in stock:
		var id := str(option.get("id", ""))
		shop_seen_counts[id] = int(shop_seen_counts.get(id, 0)) + 1


func _record_shop_visit_seen(stock: Array) -> void:
	for option in stock:
		var id := str(option.get("id", ""))
		if not shop_visit_seen_item_ids.has(id):
			shop_visit_seen_item_ids.append(id)


func _stock_has_item_id(stock: Array, id: String) -> bool:
	for option in stock:
		if str(option.get("id", "")) == id:
			return true
	return false


func _scaled_shop_cost(base_cost: int, rarity: String = "common") -> int:
	return EconomyRulesScript.scaled_shop_cost(base_cost, rarity, wave)


func _choose_shop_option(item: Dictionary) -> void:
	if not _choice_option_is_current(item) or _choice_option_disabled(item):
		return

	if item["id"] == "next_round":
		_open_next_reward_or_round()
		return

	var cost := _option_cost(item)
	var spend_currency_id := str(cost.get("currency_id", ""))
	var spend_before := _currency_balance(spend_currency_id)
	var payment: Dictionary = EconomyRulesScript.spend(wallets, cost, currency_ids)
	if not bool(payment.get("ok", false)):
		if debug_currency_logging:
			print("CURRENCY_SPEND_REJECTED cost=%s before=%d error=%s" % [JSON.stringify(cost), spend_before, str(payment.get("error", "unknown"))])
		return

	if item["id"] == "reroll":
		wallets = payment.get("wallet", wallets)
		if debug_currency_logging:
			print("CURRENCY_SPEND_COMMIT option=reroll cost=%s before=%d after=%d" % [JSON.stringify(cost), spend_before, _currency_balance(spend_currency_id)])
		run_rerolls += 1
		reroll_cost += 2
		var reroll_avoid_ids: Array = shop_visit_seen_item_ids.duplicate()
		for id in _current_shop_item_ids():
			if not reroll_avoid_ids.has(id):
				reroll_avoid_ids.append(id)
		shop_stock = _roll_shop_stock(reroll_avoid_ids)
		_show_shop_overlay()
		return

	if not _can_apply_shop_purchase(item):
		_show_shop_overlay()
		return
	var purchased := _apply_shop_purchase(item)
	if not purchased:
		_show_shop_overlay()
		return
	wallets = payment.get("wallet", wallets)
	if debug_currency_logging:
		print("CURRENCY_SPEND_COMMIT option=%s cost=%s before=%d after=%d" % [str(item.get("id", "")), JSON.stringify(cost), spend_before, _currency_balance(spend_currency_id)])
	_record_shop_purchase(item)
	if str(item.get("kind", "")) != "temper":
		_remove_shop_stock(item)
	_show_shop_overlay()
	_render_weapons()


func _can_apply_shop_purchase(item: Dictionary) -> bool:
	match str(item.get("kind", "")):
		"weapon":
			return _can_add_weapon(str(item.get("weapon", "")))
		"part":
			return not _current_upgrade_target().is_empty()
		"heal", "item":
			return true
		"temper":
			return _can_temper_current_weapon()
	return false


func _apply_shop_purchase(item: Dictionary) -> bool:
	match str(item.get("kind", "")):
		"weapon":
			if not _add_weapon(str(item["weapon"])):
				return false
		"part":
			items.append(item["name"])
			_apply_weapon_part_stats(item.get("weapon_stats", {}), str(item.get("name", "")))
		"heal":
			player["hp"] = min(player["max_hp"], player["hp"] + 35.0)
		"item":
			items.append(item["name"])
			_apply_item_stats(item.get("stats", {}))
		"temper":
			return _apply_weapon_temper()
		_:
			return false
	if bool(item.get("unique", false)):
		var id := str(item.get("id", ""))
		if not purchased_shop_item_ids.has(id):
			purchased_shop_item_ids.append(id)
	return true


func _current_upgrade_target() -> Dictionary:
	if selected_weapon_id.is_empty():
		return {}
	var matches: Array = []
	for weapon in weapons:
		if str(Dictionary(weapon).get("id", "")) == selected_weapon_id:
			matches.append(weapon)
	if matches.size() != 1:
		return {}
	return matches[0]


func _can_temper_current_weapon() -> bool:
	var target := _current_upgrade_target()
	if target.is_empty():
		return false
	var recipe := DemoContentScript.weapon_temper_recipe(str(target.get("id", "")))
	return not recipe.is_empty() and int(target.get("upgrade_rank", 0)) < int(recipe.get("max_rank", 3))


func _apply_weapon_temper() -> bool:
	if not _can_temper_current_weapon():
		return false
	var target := _current_upgrade_target()
	var recipe := DemoContentScript.weapon_temper_recipe(str(target.get("id", "")))
	var multipliers: Dictionary = recipe.get("multipliers", {})
	for stat_id in multipliers.keys():
		if not target.has(stat_id):
			return false
	for stat_id in multipliers.keys():
		target[stat_id] = float(target.get(stat_id, 0.0)) * float(multipliers[stat_id])
	target["upgrade_rank"] = int(target.get("upgrade_rank", 0)) + 1
	_add_floating_text("%s %s" % [str(recipe.get("name", "장비 단련")), _roman_rank(int(target["upgrade_rank"]))], player.get("pos", Vector2.ZERO), Color("#f0643b"))
	return true


func _apply_weapon_part_stats(stats: Dictionary, part_name: String) -> void:
	if weapons.is_empty():
		return
	var weapon: Dictionary = weapons[0]
	var mods: Array = weapon.get("mods", [])
	mods.append(part_name)
	weapon["mods"] = mods
	if stats.has("damage_mult"):
		weapon["damage"] *= float(stats["damage_mult"])
	if stats.has("cooldown_mult"):
		weapon["cooldown"] *= float(stats["cooldown_mult"])
	if stats.has("range_mult"):
		weapon["range"] *= float(stats["range_mult"])
	if stats.has("speed_mult"):
		weapon["speed"] *= float(stats["speed_mult"])
	if stats.has("pierce_add"):
		weapon["pierce"] = int(weapon["pierce"]) + int(stats["pierce_add"])
	if stats.has("projectiles_add"):
		weapon["projectiles"] = int(weapon["projectiles"]) + int(stats["projectiles_add"])
	if stats.has("spread_add"):
		weapon["spread"] = float(weapon["spread"]) + float(stats["spread_add"])
	if stats.has("center_projectile"):
		weapon["center_projectile"] = bool(stats["center_projectile"])
	if stats.has("splash_add"):
		weapon["splash"] = float(weapon.get("splash", 0.0)) + float(stats["splash_add"])
	if stats.has("armor_pierce_add"):
		weapon["armor_pierce"] = float(weapon.get("armor_pierce", 0.0)) + float(stats["armor_pierce_add"])
	if stats.has("knockback_add"):
		weapon["knockback"] = float(weapon.get("knockback", 0.0)) + float(stats["knockback_add"])


func _apply_item_stats(stats: Dictionary) -> void:
	if stats.has("max_hp_add"):
		player["max_hp"] = max(1.0, player["max_hp"] + float(stats["max_hp_add"]))
		player["hp"] = min(player["max_hp"], player["hp"] + max(0.0, float(stats["max_hp_add"])))
	if stats.has("damage_mult"):
		damage_multiplier *= float(stats["damage_mult"])
	if stats.has("cooldown_mult"):
		cooldown_multiplier *= float(stats["cooldown_mult"])
	if stats.has("range_mult"):
		range_multiplier *= float(stats["range_mult"])
	if stats.has("pickup_mult"):
		player["pickup_range"] *= float(stats["pickup_mult"])
	if stats.has("speed_mult"):
		player["speed"] *= float(stats["speed_mult"])
	if stats.has("armor_add"):
		player["armor"] += float(stats["armor_add"])
	if stats.has("currency_mult"):
		currency_drop_multiplier *= float(stats["currency_mult"])
	if stats.has("xp_mult"):
		xp_multiplier *= float(stats["xp_mult"])
	if stats.has("regen_add"):
		hp_regen += float(stats["regen_add"])


func _current_weapon_id() -> String:
	if not selected_weapon_id.is_empty():
		return selected_weapon_id
	if not weapons.is_empty():
		return str(Dictionary(weapons[0]).get("id", ""))
	return ""


func _current_weapon_icon() -> String:
	var id := _current_weapon_id()
	if id.is_empty() or not weapon_catalog.has(id):
		return ""
	return str(Dictionary(weapon_catalog[id]).get("icon", ""))


func _remove_shop_stock(item: Dictionary) -> void:
	var stock_id := str(item.get("stock_id", ""))
	for i in range(shop_stock.size() - 1, -1, -1):
		if str(shop_stock[i].get("stock_id", "")) == stock_id:
			shop_stock.remove_at(i)
			return


func _start_next_round() -> void:
	wave += 1
	_set_run_rule_state(RunRulesScript.advance_checkpoint_state(run_rule_state, wave))
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	round_currency_earned = _fresh_currency_amounts()
	spider_relic_packs_this_wave = 0
	boss_spawned = false
	_set_paused(false)
	_clear_combat_state()
	_hide_overlay()
	mode = MODE_PLAY
	_render_weapons()


func _choice_option_disabled(option: Dictionary) -> bool:
	if bool(option.get("disabled", false)):
		return true
	if option.has("cost") and not EconomyRulesScript.can_pay(wallets, _option_cost(option), currency_ids):
		return true
	if str(option.get("kind", "")) == "weapon":
		return not _can_add_weapon(str(option["weapon"]))
	if str(option.get("kind", "")) == "temper":
		return not _can_temper_current_weapon()
	return false


func _sample_array(source: Array, count: int) -> Array:
	var shuffled := source.duplicate(true)
	shuffled.shuffle()
	return shuffled.slice(0, min(count, shuffled.size()))


func _relic_count(id: String) -> int:
	return int(relic_counts.get(id, 0))


func _relic_seen_count(relic: Dictionary) -> int:
	return int(relic_seen_counts.get(str(relic.get("id", "")), 0))


func _record_relic_seen(relics: Array) -> void:
	for relic in relics:
		var id := str(relic.get("id", ""))
		relic_seen_counts[id] = int(relic_seen_counts.get(id, 0)) + 1


func _relic_by_id(id: String) -> Dictionary:
	for relic in relic_catalog:
		if str(relic.get("id", "")) == id:
			return relic
	return {}


func _active_relic_summary() -> Array:
	var summary: Array = []
	for relic in relic_catalog:
		var id := str(relic.get("id", ""))
		var count := _relic_count(id)
		if count <= 0:
			continue
		var copy: Dictionary = relic.duplicate(true)
		copy["count"] = count
		summary.append(copy)
	return summary


func _relic_run_summary_text() -> String:
	var summary := _active_relic_summary()
	if summary.is_empty():
		return "계약: 없음"
	var parts := PackedStringArray()
	for relic in summary:
		var count := int(relic.get("count", 1))
		var suffix := " %s" % _roman_level(count)
		parts.append("%s%s" % [str(relic.get("name", "")), suffix])
	return "계약: %s" % ", ".join(parts)


func _record_shop_purchase(item: Dictionary) -> void:
	run_purchase_count += 1
	run_purchase_names.append(str(item.get("name", "미확인 구매")))
	var rarity := str(item.get("rarity", "common"))
	if rarity == "rare" or rarity == "legendary":
		run_rare_legendary_purchase_names.append("%s(%s)" % [str(item.get("name", "미확인 구매")), _rarity_label(rarity)])


func _record_enemy_defeat(enemy: Dictionary) -> void:
	var type := str(enemy.get("type", "zombie"))
	run_kill_count += 1
	run_kills_by_type[type] = int(run_kills_by_type.get(type, 0)) + 1
	if bool(enemy.get("checkpoint_elite", false)):
		_credit_currency("forge_core", CHECKPOINT_ELITE_CORE_BONUS)
		_set_run_rule_state(RunRulesScript.complete_elite_objective(run_rule_state, CHECKPOINT_ELITE_CORE_BONUS))
		_add_floating_text("엘리트 목표 성공 +%d 강화핵" % CHECKPOINT_ELITE_CORE_BONUS, Vector2(enemy.get("pos", player.get("pos", Vector2.ZERO))), Color("#f0643b"))
	if type == "final_boss" or (type == "boss" and wave >= MAX_ROUNDS):
		run_boss_defeated = true


func _run_result_label() -> String:
	if mode == MODE_VICTORY or run_boss_defeated:
		return "승리"
	if mode == MODE_GAME_OVER or float(player.get("hp", 0.0)) <= 0.0:
		return "패배"
	return "진행 중"


func _run_report_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("결과 %s / 도달 라운드 %d/%d / 생존 %s" % [_run_result_label(), wave, MAX_ROUNDS, _format_time(elapsed)])
	lines.append("선택 무기: %s" % _selected_weapon_report_text())
	for currency_id in currency_ids:
		var definition := _currency_definition(str(currency_id))
		var entry: Dictionary = wallets.get(str(currency_id), {})
		var source_note := " / 라운드 고정 %d" % run_round_clear_ore if str(currency_id) == "ore" else ""
		lines.append("%s 획득 %d / 사용 %d / 보유 %d%s" % [
			str(definition.get("name", currency_id)),
			int(entry.get("acquired", 0)),
			int(entry.get("spent", 0)),
			int(entry.get("balance", 0)),
			source_note,
		])
	lines.append("상점 리롤 %d회" % run_rerolls)
	lines.append("구매 %d회 / 희귀·전설: %s" % [run_purchase_count, _format_name_counts(run_rare_legendary_purchase_names, "없음")])
	lines.append("계약: %s" % _format_relic_counts_for_report())
	lines.append("체크포인트: %s" % _checkpoint_route_history_text())
	var elite_history := _elite_result_history_text()
	if not elite_history.is_empty():
		lines.append("엘리트 결과: %s" % elite_history)
	for feedback in _checkpoint_feedback_lines():
		lines.append(feedback)
	lines.append("전투 처치 %d (%s)" % [
		run_kill_count,
		_format_kill_counts_for_report(),
	])
	lines.append("보스 피해 %d / 보스 %s" % [
		int(round(run_boss_damage)),
		"처치" if run_boss_defeated else "미처치",
	])
	return lines


func _checkpoint_route_history_text() -> String:
	var history: Array = run_rule_state.get("route_history", [])
	if history.is_empty():
		return "선택 없음"
	var parts := PackedStringArray()
	for entry in history:
		parts.append("R%d %s" % [int(entry.get("checkpoint_round", 0)), _checkpoint_route_label(str(entry.get("route", "")))])
	return " / ".join(parts)


func _checkpoint_route_label(route_id: String) -> String:
	match route_id:
		"safe":
			return "안전"
		"risk":
			return "위험"
		"shop":
			return "상점"
		"elite":
			return "엘리트"
		_:
			return "미확인"


func _elite_result_history_text() -> String:
	var results: Array = run_rule_state.get("elite_results", [])
	if results.is_empty():
		return ""
	var parts := PackedStringArray()
	for result in results:
		var checkpoint_round := int(result.get("checkpoint_round", 0))
		if str(result.get("status", "")) == "success":
			parts.append("R%d 성공 +%d 강화핵" % [checkpoint_round, int(result.get("bonus", 0))])
		else:
			parts.append("R%d 놓침" % checkpoint_round)
	return " / ".join(parts)


func _checkpoint_feedback_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var risks: Array = run_rule_state.get("persistent_risks", [])
	if risks.is_empty():
		lines.append("지속 위험: 없음")
	else:
		var names := PackedStringArray()
		for risk in risks:
			var relic := _relic_by_id(str(risk.get("id", "")))
			var name := str(relic.get("name", risk.get("id", "미확인 위험")))
			var danger := str(relic.get("danger", "적 압박 증가"))
			names.append("%s · %s · 런 지속" % [name, danger])
		lines.append("지속 위험: %s" % " / ".join(names))
	var elite: Dictionary = run_rule_state.get("elite_segment", {})
	match str(elite.get("status", "")):
		"active":
			lines.append("엘리트 목표: R%d-R%d 강적 추적 중" % [int(elite.get("start_round", 0)), int(elite.get("end_round", 0))])
		"success":
			lines.append("엘리트 목표: 성공 · 처치 보너스 +%d 강화핵" % int(elite.get("bonus", 0)))
		"missed":
			lines.append("엘리트 목표: 구간 종료 · 보너스 놓침")
	return lines


func _checkpoint_hud_feedback_lines() -> PackedStringArray:
	if checkpoint_feedback_dirty:
		checkpoint_feedback_cache = _checkpoint_feedback_lines()
		checkpoint_feedback_dirty = false
	return checkpoint_feedback_cache


func _set_run_rule_state(next_state: Dictionary) -> void:
	run_rule_state = next_state
	checkpoint_feedback_dirty = true


func _fresh_currency_amounts() -> Dictionary:
	var amounts := {}
	for currency_id in currency_ids:
		amounts[str(currency_id)] = 0
	return amounts


func _currency_balance(currency_id: String) -> int:
	return int(Dictionary(wallets.get(currency_id, {})).get("balance", 0))


func _currency_definition(currency_id: String) -> Dictionary:
	return currency_registry.get(currency_id, {})


func _credit_currency(currency_id: String, amount: int) -> bool:
	var before := _currency_balance(currency_id)
	var result: Dictionary = EconomyRulesScript.credit(wallets, currency_id, amount, currency_ids)
	if not bool(result.get("ok", false)):
		print("CURRENCY_CREDIT_REJECTED currency=%s amount=%d error=%s" % [currency_id, amount, str(result.get("error", "unknown"))])
		return false
	wallets = result.get("wallet", wallets)
	round_currency_earned[currency_id] = int(round_currency_earned.get(currency_id, 0)) + amount
	if debug_currency_logging:
		print("CURRENCY_CREDIT currency=%s amount=%d before=%d after=%d" % [currency_id, amount, before, _currency_balance(currency_id)])
	return true


func _typed_cost(currency_id: String, amount: int) -> Dictionary:
	return {"currency_id": currency_id, "amount": amount}


func _option_cost(option: Dictionary) -> Dictionary:
	var raw_cost: Variant = option.get("cost", {})
	if raw_cost is Dictionary:
		return Dictionary(raw_cost).duplicate(true)
	if raw_cost is int or raw_cost is float:
		return _typed_cost("ore", 0) if float(raw_cost) == 0.0 else {}
	return _typed_cost("ore", 0)


func _round_currency_summary() -> String:
	var parts := PackedStringArray()
	for currency_id in currency_ids:
		var amount := int(round_currency_earned.get(str(currency_id), 0))
		if amount <= 0:
			continue
		var definition := _currency_definition(str(currency_id))
		parts.append("+%d %s" % [amount, str(definition.get("name", currency_id))])
	return "획득 없음" if parts.is_empty() else " · ".join(parts)


func _wallet_balance_summary() -> String:
	var parts := PackedStringArray()
	for currency_id in currency_ids:
		var definition := _currency_definition(str(currency_id))
		parts.append("%s %d" % [str(definition.get("name", currency_id)), _currency_balance(str(currency_id))])
	return " · ".join(parts)


func _set_currency_ledger_for_debug(currency_id: String, balance: int, acquired: int, spent: int) -> void:
	if not wallets.has(currency_id):
		return
	wallets[currency_id] = {"balance": balance, "acquired": acquired, "spent": spent}


func _set_round_currency_amount(currency_id: String, amount: int) -> void:
	round_currency_earned[currency_id] = amount


func _selected_weapon_report_text() -> String:
	var id := _current_weapon_id()
	if id.is_empty() or not weapon_catalog.has(id):
		return "없음"
	var weapon: Dictionary = weapon_catalog[id]
	var target := _current_upgrade_target()
	return "%s · %s · 단련 %s" % [str(weapon.get("name", id)), str(weapon.get("family", "")), _roman_rank(int(target.get("upgrade_rank", 0)))]


func _run_report_text() -> String:
	return "\n".join(_run_report_lines())


func _run_report_console_summary() -> String:
	return " / ".join(_run_report_lines())


func _format_name_counts(names: Array, empty_text: String) -> String:
	if names.is_empty():
		return empty_text
	var counts := {}
	var order: Array = []
	for raw_name in names:
		var name := str(raw_name)
		if not counts.has(name):
			counts[name] = 0
			order.append(name)
		counts[name] = int(counts[name]) + 1
	var parts := PackedStringArray()
	for name in order:
		var count := int(counts[name])
		if count <= 1:
			parts.append(str(name))
		else:
			parts.append("%s x%d" % [str(name), count])
	return ", ".join(parts)


func _format_relic_counts_for_report() -> String:
	var summary := _active_relic_summary()
	if summary.is_empty():
		return "없음"
	var parts := PackedStringArray()
	for relic in summary:
		var count := int(relic.get("count", 1))
		parts.append("%s %s" % [str(relic.get("name", "")), _roman_level(count)])
	return ", ".join(parts)


func _format_kill_counts_for_report() -> String:
	if run_kills_by_type.is_empty():
		return "없음"
	var parts := PackedStringArray()
	var order := ["zombie", "fast_zombie", "spider", "thrower", "shield_zombie", "toxic_spider", "bomb_miner", "elite_zombie", "mid_boss", "final_boss", "boss"]
	for type in order:
		var count := int(run_kills_by_type.get(type, 0))
		if count > 0:
			parts.append("%s %d" % [_enemy_type_label(type), count])
	for type in run_kills_by_type.keys():
		if order.has(str(type)):
			continue
		parts.append("%s %d" % [_enemy_type_label(str(type)), int(run_kills_by_type[type])])
	return ", ".join(parts)


func _enemy_type_label(type: String) -> String:
	match type:
		"zombie":
			return "좀비"
		"fast_zombie":
			return "빠른 좀비"
		"spider":
			return "거미"
		"thrower":
			return "투척 좀비"
		"shield_zombie":
			return "방패 좀비"
		"toxic_spider":
			return "독 거미"
		"bomb_miner":
			return "자폭 광부"
		"elite_zombie":
			return "엘리트"
		"mid_boss":
			return "중간 보스"
		"final_boss":
			return "최종 보스"
		"boss":
			return "보스"
		_:
			return type


func _contract_enemy_hp_multiplier(kind: String) -> float:
	return RunRulesScript.contract_enemy_hp_multiplier(kind, relic_counts)


func _contract_enemy_damage_multiplier(kind: String) -> float:
	return RunRulesScript.contract_enemy_damage_multiplier(kind, relic_counts)


func _contract_enemy_speed_multiplier(kind: String) -> float:
	return RunRulesScript.contract_enemy_speed_multiplier(kind, relic_counts)


func _contract_thrower_cooldown_multiplier() -> float:
	return RunRulesScript.contract_thrower_cooldown_multiplier(relic_counts)


func _should_make_contract_elite(kind: String) -> bool:
	var chance := RunRulesScript.contract_elite_chance(kind, wave, relic_counts)
	return chance > 0.0 and randf() < chance


func _contract_currency_multiplier(enemy: Dictionary, currency_id: String) -> float:
	return RunRulesScript.contract_currency_multiplier(enemy, currency_id, relic_counts)


func _relic_clear_currency_multiplier() -> float:
	return 1.0


func _should_spawn_elite_zombie() -> bool:
	var count := _relic_count("chosen_prey")
	if count <= 0 or wave < 2:
		return false
	if enemies.size() >= _enemy_cap():
		return false
	var chance: float = min(0.22, 0.045 * float(count))
	if _round_is_boss(wave):
		chance *= 0.65
	return randf() < chance


func _should_spawn_checkpoint_elite() -> bool:
	var segment: Dictionary = run_rule_state.get("elite_segment", {})
	if str(segment.get("status", "")) != "active" or bool(segment.get("spawned", false)):
		return false
	return wave >= int(segment.get("start_round", 0)) and wave <= int(segment.get("end_round", 0)) and enemies.size() < _enemy_cap()


func _game_over() -> void:
	mode = MODE_GAME_OVER
	_show_game_over_overlay()


func _victory() -> void:
	mode = MODE_VICTORY
	_show_victory_overlay()


func _draw() -> void:
	var shake := Vector2.ZERO
	if screen_shake > 0.0:
		shake = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)) * screen_shake
	draw_world_offset = -_camera_origin() + shake
	draw_set_transform(draw_world_offset, 0.0, Vector2.ONE)
	_draw_ground()
	_draw_spawn_warnings()
	_draw_hazard_zones()
	_draw_pickups()
	_draw_bullets()
	_draw_enemy_projectiles()
	_draw_enemies()
	_draw_player()
	_draw_sparks()
	_draw_floating_text()
	draw_world_offset = Vector2.ZERO
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if paused:
		draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0, 0, 0, 0.22), true)


func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#171a15"), true)
	for x in range(0, int(WORLD_SIZE.x) + 120, 44):
		draw_line(Vector2(x, 0), Vector2(x - 120, WORLD_SIZE.y), Color(1, 0.96, 0.9, 0.045), 1.0)
	for i in range(190):
		var x := float((i * 97) % int(WORLD_SIZE.x))
		var y := float((i * 181) % int(WORLD_SIZE.y))
		draw_rect(Rect2(Vector2(x, y), Vector2(3 + i % 3, 3 + i % 4)), Color(0.9, 0.72, 0.36, 0.08), true)


func _draw_spawn_warnings() -> void:
	for warning in spawn_warnings:
		var pos: Vector2 = warning.get("pos", player.get("pos", WORLD_SIZE * 0.5))
		var duration: float = maxf(0.01, float(warning.get("duration", SPAWN_WARNING_DURATION)))
		var timer: float = clampf(float(warning.get("timer", duration)), 0.0, duration)
		var progress: float = 1.0 - timer / duration
		var kind := str(warning.get("kind", "zombie"))
		var pack_size := int(warning.get("pack_size", 1))
		var seed_value := float(warning.get("seed", 0.0))
		var base_radius := 25.0 + 4.0 * float(pack_size)
		if _is_boss_type(kind):
			base_radius = 68.0
		elif kind == "elite_zombie":
			base_radius = 46.0
		var pulse := sin(elapsed * 18.0 + seed_value) * 0.5 + 0.5
		var radius: float = base_radius + pulse * 7.0 + progress * 9.0
		var dirt := Color("#8b7254")
		dirt.a = 0.28 + 0.32 * pulse
		_draw_ellipse_shadow(pos + Vector2(0, 8), Vector2(radius * 1.25, 7.0 + pulse * 2.5), Color(0, 0, 0, 0.22))
		draw_arc(pos, radius, 0.0, TAU, 52, dirt, 3.0)
		draw_arc(pos, radius * 0.62, sin(elapsed * 3.0), TAU + sin(elapsed * 3.0), 36, Color(0.78, 0.64, 0.42, 0.26), 2.0)
		for i in range(7):
			var angle := seed_value + elapsed * (2.0 + float(i) * 0.13) + float(i) * TAU / 7.0
			var distance: float = radius * (0.24 + 0.54 * absf(sin(seed_value * 1.37 + float(i) * 2.11)))
			var pebble_pos: Vector2 = pos + Vector2.RIGHT.rotated(angle) * distance
			var size := 2.0 + float((i + pack_size) % 3)
			draw_rect(Rect2(pebble_pos - Vector2(size, size) * 0.5, Vector2(size, size)), Color(0.67, 0.49, 0.29, 0.38 + 0.25 * progress), true)
		var crack_color := Color("#32271f")
		crack_color.a = 0.28 + 0.35 * progress
		draw_line(pos + Vector2(-radius * 0.50, -2.0), pos + Vector2(-radius * 0.16, 2.0 + pulse * 3.0), crack_color, 2.0)
		draw_line(pos + Vector2(radius * 0.18, 1.0), pos + Vector2(radius * 0.54, -3.0 - pulse * 2.0), crack_color, 2.0)
		if timer < 0.22:
			var flash := Color("#e6b85c")
			flash.a = 0.15 + pulse * 0.22
			draw_circle(pos, radius * 0.82, flash)


func _draw_player() -> void:
	var pos: Vector2 = player["pos"]
	draw_circle(pos, player["pickup_range"], Color(0.9, 0.72, 0.36, 0.08))
	draw_arc(pos, player["pickup_range"], 0.0, TAU, 96, Color(0.9, 0.72, 0.36, 0.16), 2.0)
	_draw_player_sprite(pos)


func _draw_enemies() -> void:
	for enemy in enemies:
		var pos: Vector2 = _enemy_draw_pos(enemy)
		var radius: float = enemy["radius"]
		var type := str(enemy.get("type", "zombie"))
		if _draw_enemy_asset_sprite(enemy):
			pass
		elif type == "shield_zombie":
			draw_circle(pos, radius, enemy["color"])
			var front := (Vector2(player.get("pos", pos + Vector2.RIGHT)) - pos).normalized()
			var left := front.rotated(PI * 0.5)
			var shield_poly := PackedVector2Array([
				pos + front * radius * 1.22,
				pos + left * radius * 0.84,
				pos - front * radius * 0.10,
				pos - left * radius * 0.84,
			])
			draw_colored_polygon(shield_poly, Color("#c7b08a"))
			draw_arc(pos, radius + 5.0, front.angle() - 0.85, front.angle() + 0.85, 24, Color("#d8f3ff"), 3.0)
		elif type == "toxic_spider":
			for leg in range(4):
				var angle := -0.95 + float(leg) * 0.64
				draw_line(pos, pos + Vector2.LEFT.rotated(angle) * radius * 1.65, Color("#30422e"), 2.0)
				draw_line(pos, pos + Vector2.RIGHT.rotated(-angle) * radius * 1.65, Color("#30422e"), 2.0)
			draw_circle(pos, radius, enemy["color"])
			draw_circle(pos, radius * 0.52, Color("#d7f7a1"))
		elif type == "bomb_miner":
			var warning_color := Color("#f0643b") if str(enemy.get("bomb_state", "")) == "windup" else Color("#c9823a")
			draw_circle(pos, radius, enemy["color"])
			draw_rect(Rect2(pos - Vector2(radius * 0.46, radius * 0.72), Vector2(radius * 0.92, radius * 1.44)), warning_color, false, 3.0)
			if str(enemy.get("bomb_state", "")) == "windup":
				draw_arc(pos, radius + 8.0, 0.0, TAU, 32, Color("#f0643b"), 4.0)
		elif type == "spider":
			for leg in range(4):
				var angle := -0.95 + float(leg) * 0.64
				var left := Vector2.LEFT.rotated(angle)
				var right := Vector2.RIGHT.rotated(-angle)
				draw_line(pos, pos + left * radius * 1.75, Color("#30422e"), 2.0)
				draw_line(pos, pos + right * radius * 1.75, Color("#30422e"), 2.0)
			draw_circle(pos, radius, enemy["color"])
			draw_circle(pos + Vector2(radius * 0.25, -radius * 0.25), radius * 0.36, Color("#d8ceb9"))
		elif type == "thrower":
			draw_circle(pos, radius, enemy["color"])
			draw_circle(pos + Vector2(radius * 0.48, -radius * 0.46), radius * 0.34, Color("#c7b08a"))
			draw_circle(pos + Vector2(-radius * 0.22, -radius * 0.14), radius * 0.24, Color(0, 0, 0, 0.30))
		elif _is_boss_type(type):
			draw_circle(pos, radius + 5.0, Color("#3f324b"))
			draw_circle(pos, radius, enemy["color"])
			draw_arc(pos, radius + 8.0, 0.0, TAU, 72, Color("#c7b08a"), 4.0)
			draw_circle(pos + Vector2(-radius * 0.18, -radius * 0.16), radius * 0.26, Color("#221a28"))
		else:
			draw_circle(pos, radius, enemy["color"])
			draw_circle(pos + Vector2(-radius * 0.25, -radius * 0.2), radius * 0.35, Color(0, 0, 0, 0.28))
		if bool(enemy.get("elite", false)):
			_draw_elite_marker(pos, radius, type)
		var hit_flash: float = clamp(float(enemy.get("hit_flash", 0.0)), 0.0, 1.0)
		if hit_flash > 0.0:
			var flash_color: Color = enemy.get("hit_flash_color", Color("#f5efe3"))
			flash_color.a = 0.18 + 0.24 * hit_flash
			draw_circle(pos, radius * (1.08 + 0.12 * hit_flash), flash_color)
			flash_color.a = 0.58 * hit_flash
			draw_arc(pos, radius + 7.0 + 5.0 * hit_flash, -PI * 0.12, TAU - PI * 0.12, 48, flash_color, 3.0)
		var hp_ratio: float = clamp(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
		var hp_width := radius * 2.0
		var hp_y := -radius - 9.0
		if _enemy_has_sprite_asset(type):
			hp_width = _enemy_asset_hp_width(type, radius)
			hp_y = _enemy_asset_hp_y(type, radius)
		var hp_color := Color("#e6b85c")
		if hit_flash > 0.0 and (type == "boss" or type == "elite_zombie"):
			hp_color = Color(enemy.get("hit_flash_color", Color("#d8f3ff")))
		draw_rect(Rect2(pos + Vector2(-hp_width * 0.5, hp_y), Vector2(hp_width, 4)), Color("#111412"), true)
		draw_rect(Rect2(pos + Vector2(-hp_width * 0.5, hp_y), Vector2(hp_width * hp_ratio, 4)), hp_color, true)


func _draw_elite_marker(pos: Vector2, radius: float, type: String) -> void:
	var hp_y := -radius - 9.0
	if _enemy_has_sprite_asset(type):
		hp_y = _enemy_asset_hp_y(type, radius)
	var marker_pos := pos + Vector2(radius * 0.82, hp_y - 10.0)
	var outer := PackedVector2Array([
		marker_pos + Vector2(0, -8),
		marker_pos + Vector2(8, 0),
		marker_pos + Vector2(0, 8),
		marker_pos + Vector2(-8, 0),
	])
	var inner := PackedVector2Array([
		marker_pos + Vector2(0, -5),
		marker_pos + Vector2(5, 0),
		marker_pos + Vector2(0, 5),
		marker_pos + Vector2(-5, 0),
	])
	draw_colored_polygon(outer, Color("#111412"))
	draw_colored_polygon(inner, Color("#e6b85c"))
	var baseline_y := radius + 9.0
	var line_color := Color("#e6b85c")
	line_color.a = 0.78
	draw_line(pos + Vector2(-radius * 0.58, baseline_y), pos + Vector2(radius * 0.58, baseline_y), line_color, 3.0)


func _enemy_has_sprite_asset(type: String) -> bool:
	return type == "zombie" or type == "fast_zombie" or type == "spider" or type == "thrower" or type == "shield_zombie" or type == "elite_zombie" or _is_boss_type(type)


func _draw_enemy_asset_sprite(enemy: Dictionary) -> bool:
	var type := str(enemy.get("type", "zombie"))
	match type:
		"zombie":
			_draw_profiled_enemy_sprite(enemy, zombie_idle_texture, ZOMBIE_VISUAL_SCALE, "shamble", Vector2(25, 5), 29.0)
			return true
		"fast_zombie":
			_draw_profiled_enemy_sprite(enemy, fast_zombie_texture, 0.225, "sprint", Vector2(23, 4.5), 28.0)
			return true
		"spider":
			_draw_profiled_enemy_sprite(enemy, spider_swarm_texture, 0.175, "skitter", Vector2(20, 4), 20.0)
			return true
		"thrower":
			_draw_profiled_enemy_sprite(enemy, thrower_zombie_texture, 0.265, "throw", Vector2(27, 5), 30.0)
			return true
		"shield_zombie":
			_draw_profiled_enemy_sprite(enemy, shield_zombie_texture, 0.285, "brace", Vector2(34, 6), 34.0)
			return true
		"elite_zombie":
			_draw_profiled_enemy_sprite(enemy, zombie_idle_texture, 0.34, "heavy", Vector2(36, 7), 42.0)
			return true
		"boss", "mid_boss", "final_boss":
			_draw_profiled_enemy_sprite(enemy, boss_zombie_texture, 0.44, "heavy", Vector2(48, 9), 52.0)
			return true
	return false


func _draw_profiled_enemy_sprite(
	enemy: Dictionary,
	texture: Texture2D,
	base_scale: float,
	motion_profile: String,
	shadow_size: Vector2,
	shadow_y: float
) -> void:
	var ground_pos: Vector2 = enemy["pos"]
	var pos := _enemy_draw_pos(enemy)
	var faces_right := player.has("pos") and float(player["pos"].x) > ground_pos.x
	var sign := 1.0 if faces_right else -1.0
	var period := _enemy_motion_period(motion_profile)
	var phase := fposmod(elapsed + float(enemy["id"]) * 0.11, period) / period * TAU
	var pose := _enemy_motion_pose(motion_profile, phase)
	var hp: float = enemy["hp"]
	var max_hp: float = enemy["max_hp"]
	var flash: float = 1.0 - clamp(hp / max_hp, 0.0, 1.0)
	var modulate := Color(1.0, 1.0 - flash * 0.18, 1.0 - flash * 0.18)
	var hit_flash: float = clamp(float(enemy.get("hit_flash", 0.0)), 0.0, 1.0)
	if hit_flash > 0.0:
		var hit_color: Color = enemy.get("hit_flash_color", Color("#f5efe3"))
		modulate = modulate.lerp(hit_color, hit_flash * 0.54)

	_draw_ellipse_shadow(
		ground_pos + Vector2(0, shadow_y + float(pose.shadow_y_offset)),
		shadow_size * Vector2(pose.shadow_scale_x, pose.shadow_scale_y),
		Color(0, 0, 0, float(pose.shadow_alpha))
	)
	_draw_sprite_part(texture, pos, pose.local_pos, sign, pose.local_rot, pose.local_scale, base_scale, modulate)


func _enemy_motion_period(profile: String) -> float:
	match profile:
		"sprint":
			return 0.42
		"brace":
			return 0.92
		"heavy":
			return 1.24
		"skitter":
			return 0.36
		"throw":
			return 0.88
	return 0.82


func _enemy_motion_pose(profile: String, phase: float) -> Dictionary:
	var step := sin(phase)
	var drag := cos(phase)
	var lift := (1.0 - cos(phase)) * 0.5
	var double_step := sin(phase * 2.0)

	match profile:
		"sprint":
			var foot := absf(double_step)
			var stretch := pow(maxf(0.0, drag), 1.25)
			var compress := pow(maxf(0.0, -drag), 1.15)
			return {
				"local_pos": Vector2(1.90 * stretch - 0.68 * compress + 0.24 * double_step, -0.30 * foot),
				"local_rot": deg_to_rad(-3.2 + 0.55 * step),
				"local_scale": Vector2(1.0 - 0.020 * compress + 0.046 * stretch, 1.0 + 0.016 * compress - 0.028 * stretch),
				"shadow_scale_x": 1.04 + 0.090 * stretch,
				"shadow_scale_y": 0.68 + 0.010 * stretch,
				"shadow_alpha": 0.065 + 0.010 * stretch,
				"shadow_y_offset": 0.0
			}
		"brace":
			var stretch := pow(maxf(0.0, cos(phase + PI * 0.10)), 1.35)
			var compress := pow(maxf(0.0, -cos(phase + PI * 0.10)), 1.15)
			var brace_step := absf(sin(phase + PI * 0.10))
			return {
				"local_pos": Vector2(0.90 * stretch - 0.34 * compress, -0.12 * brace_step),
				"local_rot": deg_to_rad(-0.55 + 0.22 * step),
				"local_scale": Vector2(1.0 - 0.010 * compress + 0.024 * stretch, 1.0 + 0.010 * compress - 0.014 * stretch),
				"shadow_scale_x": 1.04 + 0.058 * stretch,
				"shadow_scale_y": 0.70 + 0.008 * stretch,
				"shadow_alpha": 0.070 + 0.008 * stretch,
				"shadow_y_offset": -2.0
			}
		"heavy":
			var stretch := pow(maxf(0.0, drag), 1.40)
			var compress := pow(maxf(0.0, -drag), 1.10)
			var settle := pow(lift, 2.0)
			return {
				"local_pos": Vector2(0.52 * stretch - 0.22 * compress + 0.10 * step, 0.20 * settle),
				"local_rot": deg_to_rad(-0.35 * stretch + 0.18 * step),
				"local_scale": Vector2(1.0 - 0.010 * compress + 0.026 * stretch, 1.0 + 0.012 * compress - 0.014 * stretch),
				"shadow_scale_x": 1.03 + 0.070 * stretch + 0.020 * settle,
				"shadow_scale_y": 0.72 + 0.010 * stretch,
				"shadow_alpha": 0.085 + 0.012 * stretch,
				"shadow_y_offset": -2.0
			}
		"skitter":
			var skitter := absf(double_step)
			return {
				"local_pos": Vector2(1.15 * double_step + 0.35 * drag, -0.28 * skitter),
				"local_rot": deg_to_rad(0.85 * double_step),
				"local_scale": Vector2(1.0 + 0.006 * skitter, 1.0 - 0.005 * skitter),
				"shadow_scale_x": 1.04 + 0.025 * skitter,
				"shadow_scale_y": 0.70,
				"shadow_alpha": 0.075 + 0.006 * skitter,
				"shadow_y_offset": -1.0
			}
		"throw":
			var stretch := pow(maxf(0.0, drag), 1.25)
			var compress := pow(maxf(0.0, -drag), 1.15)
			return {
				"local_pos": Vector2(0.95 * stretch - 0.42 * compress + 0.12 * double_step, -0.14 * absf(double_step)),
				"local_rot": deg_to_rad(-0.82 * stretch + 0.28 * step),
				"local_scale": Vector2(1.0 - 0.012 * compress + 0.026 * stretch, 1.0 + 0.010 * compress - 0.016 * stretch),
				"shadow_scale_x": 1.03 + 0.040 * stretch,
				"shadow_scale_y": 0.68 + 0.006 * stretch,
				"shadow_alpha": 0.065 + 0.007 * stretch,
				"shadow_y_offset": 0.0
			}

	var limp := maxf(0.0, step)
	var stretch := pow(maxf(0.0, drag), 1.30)
	var compress := pow(maxf(0.0, -drag), 1.10)
	return {
		"local_pos": Vector2(1.05 * stretch - 0.45 * compress + 0.12 * double_step, -0.18 * limp),
		"local_rot": deg_to_rad(-0.95 * stretch + 0.32 * step),
		"local_scale": Vector2(1.0 - 0.014 * compress + 0.030 * stretch + 0.004 * limp, 1.0 + 0.012 * compress - 0.019 * stretch),
		"shadow_scale_x": 1.02 + 0.050 * stretch,
		"shadow_scale_y": 0.68 + 0.006 * stretch,
		"shadow_alpha": 0.065 + 0.008 * stretch,
		"shadow_y_offset": 0.0
	}


func _enemy_draw_pos(enemy: Dictionary) -> Vector2:
	var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
	var timer := float(enemy.get("emerge_timer", 0.0))
	if timer <= 0.0:
		return pos
	var duration: float = maxf(0.01, float(enemy.get("emerge_duration", ENEMY_EMERGE_DURATION)))
	var progress: float = clampf(1.0 - timer / duration, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - progress, 2.0)
	return pos + Vector2(0.0, (1.0 - eased) * 34.0)


func _enemy_asset_hp_width(type: String, radius: float) -> float:
	match type:
		"fast_zombie":
			return 38.0
		"spider":
			return 32.0
		"thrower":
			return 46.0
		"shield_zombie":
			return 56.0
		"elite_zombie":
			return 58.0
		"boss", "mid_boss", "final_boss":
			return 96.0
	return max(42.0, radius * 2.0)


func _enemy_asset_hp_y(type: String, radius: float) -> float:
	match type:
		"fast_zombie":
			return -42.0
		"spider":
			return -31.0
		"thrower":
			return -47.0
		"shield_zombie":
			return -58.0
		"elite_zombie":
			return -63.0
		"boss", "mid_boss", "final_boss":
			return -92.0
	return min(-44.0, -radius - 9.0)


func _draw_player_sprite(pos: Vector2) -> void:
	var moving := bool(player.get("moving", false))
	var faces_right := bool(player.get("facing_right", false))
	var sign := -1.0 if faces_right else 1.0
	var modulate := Color(1.0, 0.86, 0.78) if float(player.get("hurt_cooldown", 0.0)) > 0.0 else Color.WHITE

	var body_pos := Vector2.ZERO
	var body_rot := 0.0
	var body_scale := Vector2.ONE
	var left_glove_pos := Vector2(-68, 54)
	var right_glove_pos := Vector2(76, 54)
	var left_boot_pos := Vector2(-50, 106)
	var right_boot_pos := Vector2(26, 106)
	var left_glove_rot := 0.0
	var right_glove_rot := 0.0
	var left_boot_rot := 0.0
	var right_boot_rot := 0.0

	if moving:
		var phase := fposmod(elapsed, PLAYER_MOVE_PERIOD) / PLAYER_MOVE_PERIOD * TAU
		var step := sin(phase)
		var counter_step := sin(phase + PI)
		var hop := absf(step)
		var lean := sin(phase + PI * 0.18)
		var swing := cos(phase)

		body_pos = Vector2(4.0 * lean, -7.0 * hop)
		body_rot = deg_to_rad(3.4 * lean)
		body_scale = Vector2(1.0 - 0.024 * hop, 1.0 + 0.024 * hop)
		left_glove_pos += Vector2(-4.0 * swing, -2.8 * hop) + Vector2(-6.0 * swing, -4.0 * step)
		right_glove_pos += Vector2(4.8 * swing, -3.4 * hop) + Vector2(6.6 * swing, -4.6 * counter_step)
		left_glove_rot = deg_to_rad(-6.0 + 14.0 * swing)
		right_glove_rot = deg_to_rad(6.0 - 14.0 * swing)
		left_boot_pos += Vector2(0.0, 2.0 * hop) + Vector2(-7.0 * step, -8.0 * maxf(0.0, step))
		right_boot_pos += Vector2(0.0, 2.0 * hop) + Vector2(-7.0 * counter_step, -8.0 * maxf(0.0, counter_step))
		left_boot_rot = deg_to_rad(-4.0 + 10.0 * step)
		right_boot_rot = deg_to_rad(4.0 + 10.0 * counter_step)
	else:
		var phase := fposmod(elapsed, PLAYER_IDLE_PERIOD) / PLAYER_IDLE_PERIOD * TAU
		var breath := sin(phase)
		var lift := (1.0 - cos(phase)) * 0.5
		var settle := sin(phase * 2.0)

		body_pos = Vector2(0.0, -4.5 * lift + 0.9 * settle)
		body_rot = deg_to_rad(1.1 * breath)
		body_scale = Vector2(1.0 - 0.010 * lift, 1.0 + 0.014 * lift)
		left_glove_pos += Vector2(0.0, -2.2 * lift) + Vector2(-1.8 * breath, 1.2 * settle)
		right_glove_pos += Vector2(0.0, -2.5 * lift) + Vector2(-1.4 * breath, -1.0 * settle)
		left_glove_rot = deg_to_rad(-2.5 + 5.0 * sin(phase + PI * 0.18))
		right_glove_rot = deg_to_rad(2.5 + 5.0 * sin(phase + PI * 0.82))
		left_boot_pos += Vector2(0.0, 1.0 * lift) + Vector2(-0.7 * breath, 0.5 * settle)
		right_boot_pos += Vector2(0.0, 1.0 * lift) + Vector2(-0.5 * breath, -0.45 * settle)
		left_boot_rot = deg_to_rad(-1.0 + 1.7 * sin(phase + PI * 0.35))
		right_boot_rot = deg_to_rad(1.0 + 1.7 * sin(phase + PI * 0.65))

	_draw_ellipse_shadow(pos + Vector2(0, 24), Vector2(28, 6), Color(0, 0, 0, 0.20))
	_draw_sprite_part(player_left_glove_texture, pos, left_glove_pos, sign, left_glove_rot, Vector2.ONE, PLAYER_VISUAL_SCALE, modulate)
	_draw_sprite_part(player_left_boot_texture, pos, left_boot_pos, sign, left_boot_rot, Vector2.ONE, PLAYER_VISUAL_SCALE, modulate)
	_draw_sprite_part(player_right_boot_texture, pos, right_boot_pos, sign, right_boot_rot, Vector2.ONE, PLAYER_VISUAL_SCALE, modulate)
	_draw_sprite_part(player_core_body_texture, pos, body_pos, sign, body_rot, body_scale, PLAYER_VISUAL_SCALE, modulate)
	_draw_sprite_part(player_right_glove_texture, pos, right_glove_pos, sign, right_glove_rot, Vector2.ONE, PLAYER_VISUAL_SCALE, modulate)


func _draw_sprite_part(
	texture: Texture2D,
	origin: Vector2,
	local_pos: Vector2,
	facing_sign: float,
	rotation: float,
	local_scale: Vector2,
	base_scale: float,
	modulate: Color
) -> void:
	if texture == null:
		return
	var size := texture.get_size()
	var draw_pos := origin + Vector2(local_pos.x * facing_sign, local_pos.y) * base_scale
	var draw_scale := Vector2(base_scale * facing_sign * local_scale.x, base_scale * local_scale.y)
	draw_set_transform(draw_world_offset + draw_pos, rotation * facing_sign, draw_scale)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
	draw_set_transform(draw_world_offset, 0.0, Vector2.ONE)


func _draw_ellipse_shadow(pos: Vector2, scale: Vector2, color: Color) -> void:
	draw_set_transform(draw_world_offset + pos, 0.0, scale)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(draw_world_offset, 0.0, Vector2.ONE)


func _draw_bullets() -> void:
	for bullet in bullets:
		if str(bullet.get("shape", "round")) == "drill_tip":
			_draw_drill_tip_bullet(bullet)
		elif str(bullet.get("shape", "round")) == "nail":
			_draw_nail_bullet(bullet)
		else:
			if bool(bullet.get("splash_feedback", false)):
				var splash_color := Color("#f0643b")
				splash_color.a = 0.20
				draw_circle(bullet["pos"], float(bullet["radius"]) * 2.3, splash_color)
			draw_circle(bullet["pos"], bullet["radius"], bullet["color"])


func _draw_nail_bullet(bullet: Dictionary) -> void:
	var pos: Vector2 = bullet["pos"]
	var velocity: Vector2 = bullet["velocity"]
	var direction := velocity.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	var side := direction.rotated(PI * 0.5)
	var radius: float = bullet["radius"]
	var head := pos + direction * radius * 2.8
	var tail := pos - direction * radius * 4.4
	draw_line(tail, head, Color("#111412"), radius * 2.0)
	draw_line(tail + side * 0.5, head - direction * radius * 0.4, bullet["color"], radius * 1.05)
	draw_line(pos - direction * radius * 8.0, pos - direction * radius * 2.0, Color(0.86, 0.97, 0.94, 0.24), 2.0)
	draw_circle(head, radius * 0.72, Color("#f5efe3"))
	draw_circle(tail, radius * 0.92, Color("#6e7d83"))


func _draw_drill_tip_bullet(bullet: Dictionary) -> void:
	var pos: Vector2 = bullet["pos"]
	var velocity: Vector2 = bullet["velocity"]
	var angle := velocity.angle()
	var radius: float = bullet["radius"]
	var direction := velocity.normalized()
	if bool(bullet.get("rapid_feedback", false)):
		draw_line(pos - direction * radius * 7.0, pos - direction * radius * 1.4, Color(0.95, 0.78, 0.40, 0.28), 4.0)
		draw_line(pos - direction * radius * 4.4 + direction.rotated(PI * 0.5) * 3.0, pos - direction * radius * 1.2, Color(0.95, 0.78, 0.40, 0.18), 2.0)
	if bool(bullet.get("pierce_feedback", false)):
		draw_line(pos - direction * radius * 8.6, pos + direction * radius * 1.8, Color(0.42, 0.76, 0.75, 0.36), 4.5)
		draw_line(pos - direction * radius * 5.2, pos + direction * radius * 1.5, Color(0.86, 0.97, 0.94, 0.22), 2.0)
	if bool(bullet.get("splash_feedback", false)):
		var splash_glow := Color("#f0643b")
		splash_glow.a = 0.20
		draw_circle(pos, radius * 2.6, splash_glow)
	var outline := [
		Vector2(radius * 2.05, 0.0),
		Vector2(-radius * 1.35, -radius * 0.95),
		Vector2(-radius * 0.85, 0.0),
		Vector2(-radius * 1.35, radius * 0.95),
	]
	var body := [
		Vector2(radius * 1.55, 0.0),
		Vector2(-radius * 0.95, -radius * 0.62),
		Vector2(-radius * 0.55, 0.0),
		Vector2(-radius * 0.95, radius * 0.62),
	]
	draw_colored_polygon(_rotated_polygon(pos, angle, outline), Color("#111412"))
	draw_colored_polygon(_rotated_polygon(pos, angle, body), bullet["color"])
	if bool(bullet.get("armor_feedback", false)):
		draw_line(pos + Vector2(-radius * 0.85, 0.0).rotated(angle), pos + Vector2(radius * 1.25, 0.0).rotated(angle), Color("#d8f3ff"), 2.3)
		draw_circle(pos + Vector2(radius * 0.9, 0.0).rotated(angle), radius * 0.34, Color("#f5efe3"))
	draw_line(pos + Vector2(-radius * 0.68, -radius * 0.58).rotated(angle), pos + Vector2(radius * 0.38, radius * 0.42).rotated(angle), Color("#7d877a"), 2.0)
	draw_line(pos + Vector2(-radius * 0.12, -radius * 0.48).rotated(angle), pos + Vector2(radius * 0.78, radius * 0.32).rotated(angle), Color("#f5efe3"), 1.5)
	draw_line(pos - direction * radius * 2.4, pos - direction * radius * 0.8, Color(0.95, 0.78, 0.40, 0.22), 3.0)


func _rotated_polygon(pos: Vector2, angle: float, points: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in points:
		var point_vec: Vector2 = point
		polygon.append(pos + point_vec.rotated(angle))
	return polygon


func _draw_enemy_projectiles() -> void:
	for projectile in enemy_projectiles:
		draw_circle(projectile["pos"], projectile["radius"], projectile["color"])
		draw_arc(projectile["pos"], projectile["radius"] + 3.0, 0.0, TAU, 12, Color(0, 0, 0, 0.28), 2.0)


func _draw_pickups() -> void:
	for item in pickups:
		var pos: Vector2 = item["pos"]
		var radius: float = item["radius"]
		var color: Color = item.get("color", Color("#f5efe3"))
		match str(item.get("shape", "diamond")):
			"ring":
				draw_circle(pos, radius, color)
				draw_circle(pos, radius * 0.46, Color("#17120a"))
				draw_arc(pos, radius + 2.0, 0.0, TAU, 20, Color("#d8f3ff"), 1.5)
			"hex":
				var hex_points := PackedVector2Array()
				for index in range(6):
					hex_points.append(pos + Vector2.RIGHT.rotated(PI / 3.0 * float(index)) * radius)
				draw_colored_polygon(hex_points, color)
				draw_circle(pos, radius * 0.28, Color("#f5efe3"))
			_:
				var diamond_points := PackedVector2Array([
					pos + Vector2(0, -radius),
					pos + Vector2(radius, 0),
					pos + Vector2(0, radius),
					pos + Vector2(-radius, 0),
				])
				draw_colored_polygon(diamond_points, color)


func _draw_hazard_zones() -> void:
	for zone in hazard_zones:
		var pos: Vector2 = zone.get("pos", Vector2.ZERO)
		var radius := float(zone.get("radius", 60.0))
		var life := float(zone.get("life", 0.0))
		var max_life := maxf(0.01, float(zone.get("max_life", 1.0)))
		var alpha := clampf(life / max_life, 0.0, 1.0)
		var color: Color = zone.get("color", Color("#93c96d"))
		color.a = 0.16 + 0.12 * alpha
		draw_circle(pos, radius, color)
		color.a = 0.48 * alpha
		draw_arc(pos, radius, 0.0, TAU, 64, color, 3.0)
	for enemy in enemies:
		if not _is_boss_type(str(enemy.get("type", ""))):
			continue
		if str(enemy.get("charge_state", "")) != "windup":
			continue
		var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		var dir: Vector2 = enemy.get("charge_dir", Vector2.RIGHT)
		var warning := Color("#f0643b")
		warning.a = 0.46
		draw_line(pos, pos + dir.normalized() * 260.0, warning, 9.0)
		draw_arc(pos, float(enemy.get("radius", 42.0)) + 14.0, 0.0, TAU, 72, warning, 4.0)


func _draw_sparks() -> void:
	for spark in sparks:
		var alpha = clamp(spark["life"] / spark["max_life"], 0.0, 1.0)
		var color: Color = spark["color"]
		color.a = alpha
		if spark.get("line", false):
			draw_line(spark["from"], spark["to"], color, float(spark.get("width", 3.0)))
		elif str(spark.get("type", "")) == "pickaxe_swing":
			_draw_pickaxe_swing_spark(spark, alpha)
		elif spark.get("ring", false):
			draw_arc(spark["pos"], float(spark.get("radius", 30.0)) * (1.0 - alpha * 0.2), 0.0, TAU, 48, color, float(spark.get("width", 3.0)))
		else:
			draw_circle(spark["pos"], float(spark.get("size", 3.0)), color)


func _draw_pickaxe_swing_spark(spark: Dictionary, alpha: float) -> void:
	var origin: Vector2 = spark.get("pos", Vector2.ZERO)
	var direction: Vector2 = Vector2(spark.get("direction", Vector2.RIGHT)).normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	var radius: float = float(spark.get("radius", 120.0))
	var progress: float = 1.0 - alpha
	var base_angle: float = direction.angle()
	var start_angle: float = base_angle - 0.72
	var end_angle: float = base_angle + 0.62
	var current_angle: float = lerp(start_angle, end_angle, clampf(progress, 0.0, 1.0))
	var glow: Color = Color("#f2cf66")
	glow.a = 0.12 + alpha * 0.16
	draw_arc(origin, radius * 0.74, start_angle, current_angle, 28, glow, 13.0)
	var edge: Color = Color("#f5efe3")
	edge.a = 0.20 + alpha * 0.28
	draw_arc(origin, radius * 0.82, max(start_angle, current_angle - 0.34), current_angle, 16, edge, 3.2)
	var sprite_pos: Vector2 = origin + Vector2.RIGHT.rotated(current_angle) * radius * 0.46
	var sprite_scale: float = 0.78 + 0.08 * clampf(float(spark.get("hit_count", 0)), 0.0, 3.0)
	var sprite_color: Color = Color.WHITE
	sprite_color.a = min(1.0, 0.72 + alpha * 0.45)
	if pickaxe_swing_texture != null:
		var size := pickaxe_swing_texture.get_size()
		var shadow_color := Color(0, 0, 0, min(0.58, sprite_color.a * 0.72))
		draw_set_transform(draw_world_offset + sprite_pos + Vector2(3, 4), current_angle + PI * 0.72, Vector2(sprite_scale, sprite_scale))
		draw_texture_rect(pickaxe_swing_texture, Rect2(-size * 0.5, size), false, shadow_color)
		draw_set_transform(draw_world_offset + sprite_pos, current_angle + PI * 0.72, Vector2(sprite_scale, sprite_scale))
		draw_texture_rect(pickaxe_swing_texture, Rect2(-size * 0.5, size), false, sprite_color)
		draw_set_transform(draw_world_offset, 0.0, Vector2.ONE)


func _draw_floating_text() -> void:
	for text in floating_text:
		var color: Color = text["color"]
		color.a = clamp(text["life"] / 0.55, 0.0, 1.0)
		var shadow := Color(0, 0, 0, color.a * 0.62)
		draw_string(ui_font, text["pos"] + Vector2(1.5, 1.5), text["text"], HORIZONTAL_ALIGNMENT_CENTER, -1.0, 16, shadow)
		draw_string(ui_font, text["pos"], text["text"], HORIZONTAL_ALIGNMENT_CENTER, -1.0, 16, color)


func _build_ui() -> void:
	game_ui = GameUIScript.new()
	add_child(game_ui)
	game_ui.setup(ui_font)
	game_ui.start_requested.connect(_start_run)
	game_ui.option_selected.connect(_on_ui_option_selected)
	game_ui.resume_requested.connect(func(): _set_paused(false))
	game_ui.restart_requested.connect(_start_run)


func _show_start_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_start(
		"봉인된 채굴지",
		"다중 화폐 원정",
		"10라운드 광맥에 들어가기 전에 곡괭이, 네일건, 랜턴 중 하나를 고르세요. 적과 위험에 따라 다른 성장 재료를 발견할 수 있습니다.",
		"탐사 시작"
	)


func _show_choice_overlay(eyebrow_text: String, title_text: String, options: Array, method_name: String) -> void:
	active_choice_generation += 1
	active_choice_options = []
	for index in range(options.size()):
		var option: Dictionary = Dictionary(options[index]).duplicate(true)
		if option.has("cost"):
			option["cost"] = _option_cost(option)
		option["choice_generation"] = active_choice_generation
		option["stable_id"] = str(option.get("stock_id", option.get("id", "option_%d" % index)))
		active_choice_options.append(option)
	active_choice_method = method_name
	game_ui.show_choice(eyebrow_text, title_text, _decorate_choice_options(active_choice_options), _active_relic_summary(), _current_state_summary())


func _show_game_over_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_end(
		"탐사 종료",
		"다중 화폐 런 요약",
		_run_report_text(),
		"다시 도전",
		_active_relic_summary()
	)


func _show_victory_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_end(
		"탐사 완료",
		"다중 화폐 런 요약",
		_run_report_text(),
		"다시 시작",
		_active_relic_summary()
	)


func _start_run() -> void:
	_reset_run(false)
	_open_weapon_select()


func _open_weapon_select() -> void:
	mode = MODE_CHOICE
	wave = 1
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	enemies.clear()
	bullets.clear()
	_show_choice_overlay("R1 진입 전", "스타터 무기 선택", _starter_weapon_options(), "_choose_starter_weapon")


func _choose_starter_weapon(option: Dictionary) -> void:
	if str(option.get("kind", "")) != "starter_weapon":
		return
	var id := str(option.get("id", ""))
	if not starter_weapon_ids.has(id):
		return
	if not _equip_weapon_for_run(id):
		return
	_hide_overlay()
	mode = MODE_PLAY
	wave = 1
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	round_currency_earned = _fresh_currency_amounts()
	boss_spawned = false


func _hide_overlay() -> void:
	game_ui.hide_overlay()


func _render_weapons() -> void:
	game_ui.render_weapons(weapons, damage_multiplier)


func _update_hud() -> void:
	game_ui.update_hud({
		"hp": player.get("hp", 0.0),
		"max_hp": player.get("max_hp", 100.0),
		"xp": xp,
		"xp_to_next": xp_to_next,
		"level": level,
		"wave": wave,
		"max_wave": MAX_ROUNDS,
		"wallets": wallets,
		"currency_registry": currency_registry,
		"time": _format_time(max(0.0, wave_timer)),
		"relics": _active_relic_summary(),
		"risk_lines": _checkpoint_hud_feedback_lines(),
	})


func _current_state_summary() -> Dictionary:
	var weapon_lines := PackedStringArray()
	for weapon in weapons:
		var mods: Array = weapon.get("mods", [])
		var mod_names := PackedStringArray()
		for mod_name in mods:
			mod_names.append(str(mod_name))
		var mod_text := "부품 없음" if mod_names.is_empty() else ", ".join(mod_names)
		weapon_lines.append("%s · 피해 %d · 단련 %s · %s" % [
			str(weapon.get("name", "무기")),
			int(round(float(weapon.get("damage", 0.0)) * damage_multiplier)),
			_roman_rank(int(weapon.get("upgrade_rank", 0))),
			mod_text,
		])
	if weapon_lines.is_empty():
		weapon_lines.append("무기 없음")

	var lines := PackedStringArray()
	lines.append("체력 %d/%d · %s · 공세 %d/%d · 남은 시간 %s" % [
		int(round(float(player.get("hp", 0.0)))),
		int(round(float(player.get("max_hp", 100.0)))),
		_wallet_balance_summary(),
		wave,
		MAX_ROUNDS,
		_format_time(max(0.0, wave_timer)),
	])
	lines.append("무기: %s" % " / ".join(weapon_lines))
	lines.append("계약: %s" % _format_relic_counts_for_report())
	lines.append("처치 %d · 구매 %d · 리롤 %d" % [run_kill_count, run_purchase_count, run_rerolls])
	var weapon_label := "현재 무기 없음"
	if not weapons.is_empty():
		var weapon: Dictionary = weapons[0]
		weapon_label = "%s · %s · %s" % [
			str(weapon.get("name", "무기")),
			str(weapon.get("family", "")),
			str(weapon.get("feel", "")),
		]
	return {"lines": lines, "weapon_icon": _current_weapon_icon(), "weapon_label": weapon_label}


func _format_time(seconds: float) -> String:
	var mins := int(floor(seconds / 60.0))
	var secs := int(floor(fmod(seconds, 60.0)))
	return "%02d:%02d" % [mins, secs]


func _decorate_choice_options(options: Array) -> Array:
	var decorated := []
	for option in options:
		var copy: Dictionary = option.duplicate(true)
		copy["disabled"] = _choice_option_disabled(option)
		copy["meta_text"] = _choice_meta_text(option, bool(copy["disabled"]))
		decorated.append(copy)
	return decorated


func _choice_meta_text(option: Dictionary, disabled: bool) -> String:
	if disabled and not str(option.get("disabled_reason", "")).is_empty():
		return str(option.get("disabled_reason", ""))
	if disabled and str(option.get("kind", "")) == "weapon":
		return "무기 슬롯 또는 강화 한도 초과"
	if str(option.get("kind", "")) == "starter_weapon":
		return str(option.get("tag", "스타터 무기"))
	if str(option.get("kind", "")) == "relic":
		var next_level: int = min(3, _relic_count(str(option.get("id", ""))) + 1)
		return "계약 %s · %s · %s" % [_roman_level(next_level), str(option.get("danger", "위험 누적")), str(option.get("reward_hint", "더 큰 위험은 더 값진 성장 기회를 품는다."))]
	if str(option.get("kind", "")) == "checkpoint_route":
		return "%s · %s · %s" % [str(option.get("scope", "다음 구간")), str(option.get("danger", "위험 미확인")), str(option.get("outcome", "결과 미확인"))]
	if option.has("cost"):
		var cost := _option_cost(option)
		var validation := EconomyRulesScript.validate_typed_cost(cost, currency_ids)
		if not bool(validation.get("ok", false)):
			return "가격 오류"
		var amount := int(cost.get("amount", 0))
		var currency_id := str(cost.get("currency_id", ""))
		var definition := _currency_definition(currency_id)
		var price_text := "무료" if amount <= 0 else "%s %d" % [str(definition.get("name", currency_id)), amount]
		if disabled and amount > _currency_balance(currency_id):
			price_text += " · 부족"
		if option.has("rarity"):
			price_text = "%s · %s" % [_rarity_label(str(option.get("rarity", "common"))), price_text]
		if option.has("counter"):
			return "%s · %s" % [str(option["counter"]), price_text]
		if amount <= 0:
			return "무료"
		return price_text
	if option.has("tag"):
		return str(option["tag"])
	return ""


func _rarity_label(rarity: String) -> String:
	match rarity:
		"rare":
			return "레어"
		"legendary":
			return "전설"
		_:
			return "일반"


func _roman_level(level_value: int) -> String:
	match level_value:
		1:
			return "I"
		2:
			return "II"
		_:
			return "III"


func _roman_rank(rank: int) -> String:
	if rank <= 0:
		return "0"
	return _roman_level(rank)


func _on_ui_option_selected(option: Dictionary) -> void:
	if active_choice_method.is_empty():
		return
	var active_option := _active_choice_option_by_stable_id(option)
	if active_option.is_empty():
		print("CHOICE_REJECTED reason=stale_or_unoffered option=%s generation=%d" % [JSON.stringify(option), active_choice_generation])
		return
	var key := "%d:%s" % [int(active_option.get("choice_generation", -1)), str(active_option.get("stable_id", ""))]
	if bool(handled_choice_keys.get(key, false)):
		print("CHOICE_REJECTED reason=already_used key=%s" % key)
		return
	handled_choice_keys[key] = true
	Callable(self, active_choice_method).call(active_option.duplicate(true))


func _choice_option_is_current(option: Dictionary) -> bool:
	return not _active_choice_option_by_stable_id(option).is_empty()


func _active_choice_option_by_stable_id(option: Dictionary) -> Dictionary:
	if int(option.get("choice_generation", -1)) != active_choice_generation:
		return {}
	var stable_id := str(option.get("stable_id", ""))
	if stable_id.is_empty():
		return {}
	for active_option in active_choice_options:
		if int(Dictionary(active_option).get("choice_generation", -1)) == active_choice_generation and str(Dictionary(active_option).get("stable_id", "")) == stable_id:
			return Dictionary(active_option)
	return {}
