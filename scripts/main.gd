extends Node2D

const GameUIScript = preload("res://scripts/ui/game_ui.gd")
const OreUIThemeScript = preload("res://scripts/ui/ore_ui_theme.gd")

const VIEW_SIZE := Vector2(1280, 720)
const WORLD_SIZE := Vector2(2048, 2048)
const WORLD_MARGIN := 34.0
const MODE_START := "start"
const MODE_PLAY := "play"
const MODE_CHOICE := "choice"
const MODE_GAME_OVER := "game_over"
const MODE_VICTORY := "victory"
const MAX_ROUNDS := 5
const MAX_WEAPON_SLOTS := 6
const MAX_WEAPON_LEVEL := 4
const SHOP_OPTION_COUNT := 4
const RELIC_OPTION_COUNT := 3
const P1_ROUND_DURATION := 42.0
const P1_BOSS_ROUND_DURATION := 120.0
const P2_SHOP_REWARDS_ENABLED := true
const P2_LEVEL_UP_REWARDS_ENABLED := false
const ROUND_CLEAR_ORE_BASE := 20
const ROUND_CLEAR_ORE_STEP := 8
const SMOKE_ROUND_DURATION := 5.0
const SMOKE_PLAYTEST_DURATION := 70.0
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
const FAST_ZOMBIE_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v1/fast_zombie.png"
const SPIDER_SWARM_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v1/spider_swarm.png"
const THROWER_ZOMBIE_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v1/thrower_zombie.png"
const BOSS_ZOMBIE_PATH := "res://assets/sprites/characters/p1_monsters_runtime_v1/boss_zombie.png"
const CAMERA_FOLLOW_SPEED := 7.5
const SPAWN_WARNING_DURATION := 0.78
const BOSS_SPAWN_WARNING_DURATION := 1.18
const ENEMY_EMERGE_DURATION := 0.32

var mode := MODE_START
var elapsed := 0.0
var wave := 1
var wave_timer := 35.0
var spawn_timer := 0.0
var ore := 0
var level := 1
var xp := 0.0
var xp_to_next := 18.0
var damage_multiplier := 1.0
var cooldown_multiplier := 1.0
var range_multiplier := 1.0
var ore_multiplier := 1.0
var xp_multiplier := 1.0
var hp_regen := 0.0
var dash_cooldown := 0.0
var screen_shake := 0.0
var paused := false
var camera_pos := Vector2.ZERO
var draw_world_offset := Vector2.ZERO
var next_enemy_id := 1
var reroll_cost := 2
var round_ore_earned := 0
var rounds_cleared := 0
var spider_relic_packs_this_wave := 0
var debug_hurt_events := 0
var run_ore_collected := 0
var run_ore_spent := 0
var run_rerolls := 0
var run_purchase_count := 0
var run_purchase_names: Array = []
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
var enemies: Array = []
var bullets: Array = []
var enemy_projectiles: Array = []
var pickups: Array = []
var spawn_warnings: Array = []
var sparks: Array = []
var floating_text: Array = []
var boss_spawned := false

var game_ui: CanvasLayer
var ui_font: Font
var active_choice_options: Array = []
var active_choice_method := ""
var smoke_playtest := false
var smoke_elapsed := 0.0
var smoke_choices_taken := 0
var smoke_finishing := false
var player_core_body_texture: Texture2D
var player_left_glove_texture: Texture2D
var player_right_glove_texture: Texture2D
var player_left_boot_texture: Texture2D
var player_right_boot_texture: Texture2D
var zombie_idle_texture: Texture2D
var fast_zombie_texture: Texture2D
var spider_swarm_texture: Texture2D
var thrower_zombie_texture: Texture2D
var boss_zombie_texture: Texture2D

var stat_rewards := [
	{"id": "hp", "name": "강철 폐", "desc": "+18 최대 체력, 체력을 조금 회복합니다.", "tag": "생존"},
	{"id": "speed", "name": "용수철 장화", "desc": "+12% 이동 속도.", "tag": "기동"},
	{"id": "magnet", "name": "자석 광맥", "desc": "+34% 획득 범위.", "tag": "수집"},
	{"id": "damage", "name": "톱니 탄환", "desc": "+16% 무기 피해.", "tag": "공격"},
	{"id": "cooldown", "name": "빠른 손놀림", "desc": "+14% 공격 속도.", "tag": "공격"},
	{"id": "ore", "name": "광석 감각", "desc": "+40% 광석 획득.", "tag": "수집"},
	{"id": "armor", "name": "보강 재킷", "desc": "+2 접촉 피해 방어.", "tag": "생존"},
	{"id": "xp", "name": "측량 집중", "desc": "+20% 경험치.", "tag": "성장"},
]

var shop_catalog := [
	{"id": "rapid_trigger", "kind": "part", "name": "급속 방아쇠", "desc": "드릴촉 발사 간격 -18%. 빠른 좀비가 붙기 전에 깎아냅니다.", "cost": 18, "counter": "빠른 좀비 대응", "counters": [2], "icon": "res://assets/sprites/items/p2_parts/part_rapid_trigger.png", "weapon_stats": {"cooldown_mult": 0.82}},
	{"id": "piercing_bit", "kind": "part", "name": "관통 드릴촉", "desc": "드릴촉 관통 +1. 거미떼처럼 몰려오는 적을 한 줄로 뚫습니다.", "cost": 22, "counter": "거미떼 대응", "counters": [3], "icon": "res://assets/sprites/items/p2_parts/part_piercing_bit.png", "weapon_stats": {"pierce_add": 1.0, "damage_mult": 1.06}},
	{"id": "shatter_charge", "kind": "part", "name": "파편 폭약", "desc": "명중 지점에 작은 폭발을 붙입니다. 뭉친 적을 같이 지웁니다.", "cost": 28, "counter": "거미떼 대응", "counters": [3], "icon": "res://assets/sprites/items/p2_parts/part_shatter_charge.png", "weapon_stats": {"splash_add": 42.0, "damage_mult": 0.94}},
	{"id": "long_barrel", "kind": "part", "name": "긴 총열", "desc": "드릴촉 사거리 +24%, 탄속 +10%. 투척 좀비와 거리를 둡니다.", "cost": 20, "counter": "투척 좀비 대응", "counters": [4], "icon": "res://assets/sprites/items/p2_parts/part_long_barrel.png", "weapon_stats": {"range_mult": 1.24, "speed_mult": 1.10}},
	{"id": "spring_boots", "kind": "item", "name": "스프링 장화", "desc": "이동 속도 +14%. 돌 투사체를 피하고 사거리를 다시 잡습니다.", "cost": 18, "counter": "투척 좀비 대응", "counters": [4], "icon": "res://assets/sprites/items/p2_parts/part_spring_boots.png", "stats": {"speed_mult": 1.14}},
	{"id": "carbide_tip", "kind": "part", "name": "균열 탄심", "desc": "방어 관통 +3. 단단한 보스 좀비의 방어를 뚫습니다.", "cost": 30, "counter": "보스 대응", "counters": [5], "icon": "res://assets/sprites/items/p2_parts/part_carbide_tip.png", "weapon_stats": {"armor_pierce_add": 3.0, "damage_mult": 1.08}},
	{"id": "rations", "kind": "heal", "name": "야전 식량", "desc": "체력 35 회복. 상점 루프 검증용 안전 선택지입니다.", "cost": 14, "icon": "res://assets/sprites/items/p2_parts/part_rations.png"},
]

var relic_catalog := [
	{
		"id": "spider_egg_fossil",
		"kind": "relic",
		"name": "거미 알 화석",
		"desc": "위험: 거미 스폰 비율 증가. 보상: 라운드 클리어 광석 +20%.",
		"danger": "거미 증가",
		"reward": "클리어 광석 +20%",
		"icon": "res://assets/sprites/items/p3_relics/relic_spider_egg_fossil.png",
	},
	{
		"id": "hungry_lantern",
		"kind": "relic",
		"name": "굶주린 등불",
		"desc": "위험: 모든 적 이동 속도 +8%. 보상: 상점 리롤 비용 -1.",
		"danger": "적 속도 +8%",
		"reward": "리롤 비용 -1",
		"icon": "res://assets/sprites/items/p3_relics/relic_hungry_lantern.png",
	},
	{
		"id": "echoing_stone_heart",
		"kind": "relic",
		"name": "메아리나는 돌심장",
		"desc": "위험: 투척 좀비 공격이 빨라짐. 보상: 사거리/이동 부품 등장 보장.",
		"danger": "투척 쿨다운 감소",
		"reward": "사거리/이동 부품 보장",
		"icon": "res://assets/sprites/items/p3_relics/relic_echoing_stone_heart.png",
	},
	{
		"id": "red_vein_sample",
		"kind": "relic",
		"name": "붉은 광맥 표본",
		"desc": "위험: 적 수 +15%. 보상: 적 광석 드롭 확률 증가.",
		"danger": "적 수 +15%",
		"reward": "광석 드롭 증가",
		"icon": "res://assets/sprites/items/p3_relics/relic_red_vein_sample.png",
	},
	{
		"id": "black_shell",
		"kind": "relic",
		"name": "검은 탄피 유물",
		"desc": "위험: 적 체력 +10%. 보상: 상점 가격 -10%.",
		"danger": "적 체력 +10%",
		"reward": "상점 가격 -10%",
		"icon": "res://assets/sprites/items/p3_relics/relic_black_shell.png",
	},
	{
		"id": "twin_excavation_seal",
		"kind": "relic",
		"name": "쌍둥이 굴착 인장",
		"desc": "위험: 엘리트 큰 좀비가 가끔 추가 등장. 보상: 클리어 추가 광석.",
		"danger": "엘리트 추가",
		"reward": "추가 클리어 광석",
		"icon": "res://assets/sprites/items/p3_relics/relic_twin_excavation_seal.png",
	},
	{
		"id": "unstable_blast_crystal",
		"kind": "relic",
		"name": "불안정한 폭약 결정",
		"desc": "위험: 적 사망 시 위험 폭발. 보상: 폭발/광역 부품 등장 보장.",
		"danger": "사망 폭발",
		"reward": "광역 부품 보장",
		"icon": "res://assets/sprites/items/p3_relics/relic_unstable_blast_crystal.png",
	},
]

var weapon_catalog := {
	"drill_tip": {"name": "드릴촉 발사기", "fire_type": "bullet", "cooldown": 0.72, "damage": 16.0, "range": 430.0, "speed": 690.0, "color": Color("#d8ceb9"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0, "armor_pierce": 0.0, "knockback": 0.0, "shape": "drill_tip"},
	"spitter": {"name": "광석 분사기", "fire_type": "bullet", "cooldown": 0.62, "damage": 18.0, "range": 470.0, "speed": 640.0, "color": Color("#e6b85c"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"flintlock": {"name": "쌍발 화승총", "fire_type": "bullet", "cooldown": 0.54, "damage": 9.0, "range": 390.0, "speed": 760.0, "color": Color("#f0643b"), "pierce": 0, "projectiles": 2, "spread": 0.20, "splash": 0.0},
	"drill": {"name": "파편 드릴", "fire_type": "bullet", "cooldown": 1.28, "damage": 34.0, "range": 560.0, "speed": 500.0, "color": Color("#93c96d"), "pierce": 3, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"coil": {"name": "전류 코일", "fire_type": "arc", "cooldown": 1.08, "damage": 16.0, "range": 180.0, "speed": 0.0, "color": Color("#6cc3c0"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"cleaver": {"name": "녹슨 절단기", "fire_type": "slash", "cooldown": 0.86, "damage": 23.0, "range": 132.0, "speed": 0.0, "color": Color("#d8ceb9"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"launcher": {"name": "광산 유탄기", "fire_type": "explosive", "cooldown": 1.48, "damage": 26.0, "range": 520.0, "speed": 430.0, "color": Color("#d87745"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 72.0},
}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--smoke-playtest") or args.has("--debug-spider-relic-wave2") or args.has("--debug-boss-pierce-splash") or args.has("--debug-emerging-death-cleanup") or args.has("--capture-choice-ui") or args.has("--capture-shop-ui") or args.has("--capture-relic-ui") or args.has("--capture-run-report-ui") or args.has("--capture-combat-feedback") or args.has("--capture-p6-map-camera") or args.has("--capture-spawn-telegraph") or args.has("--capture-pause-ui") or args.has("--capture-stage1") or args.has("--capture-monster-roster"):
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
	elif args.has("--smoke-playtest"):
		_start_smoke_playtest.call_deferred()
	elif args.has("--debug-spider-relic-wave2"):
		_debug_spider_relic_wave2_and_quit.call_deferred()
	elif args.has("--debug-boss-pierce-splash"):
		_debug_boss_pierce_splash_and_quit.call_deferred()
	elif args.has("--debug-emerging-death-cleanup"):
		_debug_emerging_death_cleanup_and_quit.call_deferred()


func _debug_spider_relic_wave2_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	wave = 2
	rounds_cleared = 1
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	enemies.clear()
	_add_relic(_relic_by_id("spider_egg_fossil"))
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
		_relic_count("spider_egg_fossil"),
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
	level = 2
	_open_level_up()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(CHOICE_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_shop_ui_and_quit() -> void:
	_reset_run(true)
	wave = 3
	rounds_cleared = 2
	ore = 120
	_add_relic(_relic_by_id("spider_egg_fossil"))
	_add_relic(_relic_by_id("hungry_lantern"))
	_add_relic(_relic_by_id("hungry_lantern"))
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
	round_ore_earned = 34
	ore = 62
	_add_relic(_relic_by_id("red_vein_sample"))
	_open_relic_choice()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(RELIC_UI_CAPTURE_PATH)
	get_tree().quit()


func _capture_run_report_ui_and_quit() -> void:
	_reset_run(true)
	_hide_overlay()
	mode = MODE_VICTORY
	wave = MAX_ROUNDS
	rounds_cleared = MAX_ROUNDS
	level = 5
	elapsed = 78.4
	ore = 44
	run_ore_collected = 166
	run_ore_spent = 122
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
	_add_relic(_relic_by_id("spider_egg_fossil"))
	_add_relic(_relic_by_id("hungry_lantern"))
	_add_relic(_relic_by_id("hungry_lantern"))
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
	sparks.clear()
	floating_text.clear()
	_add_relic(_relic_by_id("spider_egg_fossil"))
	_add_relic(_relic_by_id("black_shell"))

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
	ore = 86
	run_kill_count = 42
	run_purchase_count = 3
	run_rerolls = 1
	_add_relic(_relic_by_id("spider_egg_fossil"))
	_add_relic(_relic_by_id("hungry_lantern"))
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
	_add_relic(_relic_by_id("unstable_blast_crystal"))
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
		{"type": "boss", "offset": Vector2(300, -65)},
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
	boss_zombie_texture = _load_png_texture(BOSS_ZOMBIE_PATH)


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Failed to load main scene visual texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _process(delta: float) -> void:
	if mode == MODE_PLAY and not paused:
		_update_game(delta)
	if smoke_playtest:
		_update_smoke_playtest(delta)
	queue_redraw()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and mode == MODE_PLAY:
		_set_paused(not paused)
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


func _reset_run(start_playing: bool) -> void:
	mode = MODE_PLAY if start_playing else MODE_START
	elapsed = 0.0
	wave = 1
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	ore = 0
	level = 1
	xp = 0.0
	xp_to_next = 14.0
	damage_multiplier = 1.0
	cooldown_multiplier = 1.0
	range_multiplier = 1.0
	ore_multiplier = 1.0
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
	reroll_cost = _shop_reroll_cost()
	round_ore_earned = 0
	rounds_cleared = 0
	spider_relic_packs_this_wave = 0
	run_ore_collected = 0
	run_ore_spent = 0
	run_rerolls = 0
	run_purchase_count = 0
	run_purchase_names.clear()
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
	sparks.clear()
	floating_text.clear()
	boss_spawned = false
	_add_weapon("drill_tip")
	_render_weapons()


func _round_duration(round_index: int) -> float:
	if smoke_playtest:
		return SMOKE_ROUND_DURATION
	if round_index >= MAX_ROUNDS:
		return P1_BOSS_ROUND_DURATION
	return P1_ROUND_DURATION


func _shop_reroll_cost() -> int:
	var base_cost: int = max(2, int(round(2.0 + wave * 0.65 + rounds_cleared * 0.25)))
	return max(1, base_cost - _relic_count("hungry_lantern"))


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
	_update_pickups(delta)
	_update_sparks(delta)
	_update_floating_text(delta)

	if wave < MAX_ROUNDS and wave_timer <= 0.0:
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
	player["max_hp"] = 260.0
	player["hp"] = 260.0
	player["armor"] = 4.0
	player["speed"] = 315.0
	damage_multiplier = 2.25
	cooldown_multiplier = 0.55


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
	if wave >= MAX_ROUNDS:
		var boss := _boss_enemy()
		if not boss.is_empty():
			return (boss["pos"] - player["pos"]).normalized()
	var angle := smoke_elapsed * 1.25
	return Vector2(cos(angle), sin(angle)).normalized()


func _choose_smoke_option() -> void:
	if active_choice_options.is_empty() or active_choice_method.is_empty():
		return

	var selected: Dictionary = {}
	for option in active_choice_options:
		var cost := int(option.get("cost", 0))
		if ore >= cost and not _choice_option_disabled(option):
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
	print("SMOKE_PLAYTEST result=%s mode=%s wave=%d level=%d hp=%.1f ore=%d enemies=%d pickups=%d choices=%d elapsed=%.2f capture=%s report=\"%s\"" % [
		result,
		mode,
		wave,
		level,
		float(player.get("hp", 0.0)),
		ore,
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

	if wave >= MAX_ROUNDS and not boss_spawned:
		_queue_spawn_warning("boss", 1, BOSS_SPAWN_WARNING_DURATION)
		boss_spawned = true
		spawn_timer = 1.8
		return

	if enemies.size() + _pending_spawn_count() >= _enemy_cap():
		spawn_timer = 0.35
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


func _spawn_enemy_pack_at(kind: String, pack_size: int, anchor: Vector2, emerging: bool) -> void:
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
			_spawn_enemy_pack_at(str(warning.get("kind", "zombie")), int(warning.get("pack_size", 1)), Vector2(warning.get("pos", player.get("pos", WORLD_SIZE * 0.5))), true)
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
			base_cap = 14
		2:
			base_cap = 18
		3:
			base_cap = 24
		4:
			base_cap = 26
		_:
			base_cap = 12
	return int(ceil(float(base_cap) * _relic_enemy_density_multiplier()))


func _pick_enemy_kind() -> String:
	var spider_relic_count := _relic_count("spider_egg_fossil")
	if wave >= 2 and spider_relic_count > 0:
		var guaranteed_spider_packs: int = min(2, spider_relic_count)
		if spider_relic_packs_this_wave < guaranteed_spider_packs:
			spider_relic_packs_this_wave += 1
			return "spider"
		var spider_pressure: float = min(0.42, 0.18 * float(spider_relic_count))
		if randf() < spider_pressure:
			spider_relic_packs_this_wave += 1
			return "spider"

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
		return randi_range(4, 5) if wave < MAX_ROUNDS else randi_range(3, 4)
	if wave >= MAX_ROUNDS and kind != "thrower":
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
		_:
			interval = 1.36
	if smoke_playtest:
		interval *= 0.62
	interval *= _relic_spawn_interval_multiplier()
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
	if kind == "boss":
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
	var dropped_ore := 1
	var ore_chance := 1.0
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
			dropped_ore = 1
			ore_chance = 0.35
			color = Color("#6f9f61")
		"thrower":
			hp = 36.0
			radius = 18.0
			speed = 66.0
			damage = 6.0
			dropped_ore = 2
			color = Color("#7e8a76")
			desired_range = 360.0
			attack_cooldown = 2.15
		"elite_zombie":
			hp = 82.0
			radius = 25.0
			speed = 62.0
			damage = 13.0
			armor = 1.0
			dropped_ore = 4
			ore_chance = 1.0
			color = Color("#8b7254")
		"boss":
			hp = 380.0
			radius = 42.0
			speed = 48.0
			damage = 16.0
			armor = 3.0
			dropped_ore = 0
			color = Color("#6f4f86")
		_:
			kind = "zombie"

	hp *= _relic_enemy_hp_multiplier()
	speed *= _relic_enemy_speed_multiplier()
	if kind == "thrower":
		attack_cooldown = max(0.72, attack_cooldown * _relic_thrower_cooldown_multiplier())
	ore_chance = min(1.0, ore_chance + _relic_ore_drop_bonus())

	var enemy_id := next_enemy_id
	next_enemy_id += 1

	return {
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
		"ore": dropped_ore,
		"ore_chance": ore_chance,
		"xp": dropped_xp,
		"desired_range": desired_range,
		"attack_timer": randf_range(0.25, max(0.35, attack_cooldown)),
		"attack_cooldown": attack_cooldown,
		"knockback_velocity": Vector2.ZERO,
		"hit_flash": 0.0,
		"hit_flash_color": Color("#f5efe3"),
		"emerge_timer": 0.0,
		"emerge_duration": ENEMY_EMERGE_DURATION,
	}


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
	if wave >= MAX_ROUNDS:
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
		if str(enemy.get("type", "")) != "boss":
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
		if str(enemy.get("type", "")) == "boss":
			return enemy
	return {}


func _fire_weapon(weapon: Dictionary, target: Dictionary, effective_range: float) -> void:
	match str(weapon.get("fire_type", "bullet")):
		"arc":
			_fire_arc(weapon, effective_range)
		"slash":
			_fire_slash(weapon, effective_range)
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
	var has_rapid_feedback := _weapon_has_mod(weapon, "급속 방아쇠")
	for i in range(projectile_count):
		var offset := 0.0
		if projectile_count > 1:
			offset = lerp(-spread, spread, float(i) / float(projectile_count - 1))
		var direction := Vector2.RIGHT.rotated(base_angle + offset)
		var bullet_radius := 5.0
		if explosive:
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
				var damage = max(1.0, projectile["damage"] - player["armor"])
				player["hp"] -= damage
				player["hurt_cooldown"] = 0.45
				screen_shake = 0.8
				_add_floating_text("-%d" % int(round(damage)), player["pos"] + Vector2(0, -28), Color("#f0643b"))
			_add_spark(projectile["pos"], projectile["color"], 8)
			enemy_projectiles.remove_at(i)
			continue

		if projectile["life"] <= 0.0 or not Rect2(Vector2(-80, -80), WORLD_SIZE + Vector2(160, 160)).has_point(projectile["pos"]):
			enemy_projectiles.remove_at(i)


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
			_record_enemy_defeat(defeated_type)
			_drop_pickups(enemy)
			_trigger_relic_death_hazard(enemy)
			_add_spark(enemy["pos"], enemy["color"], 14)
			enemies.remove_at(i)
			if defeated_type == "boss":
				_victory()
				return
			continue

		if _enemy_is_emerging(enemy):
			continue
		var direction: Vector2 = (player["pos"] - enemy["pos"]).normalized()
		var touch_distance: float = player["radius"] + enemy["radius"]
		if enemy["pos"].distance_squared_to(player["pos"]) <= touch_distance * touch_distance:
			if player["hurt_cooldown"] <= 0.0:
				var damage = max(1.0, enemy["damage"] - player["armor"])
				player["hp"] -= damage
				player["hurt_cooldown"] = 0.55
				screen_shake = 1.0
				_add_floating_text("-%d" % int(round(damage)), player["pos"] + Vector2(0, -28), Color("#f0643b"))
			enemy["pos"] += -direction * 70.0 * delta


func _update_enemy_behavior(enemy: Dictionary, delta: float) -> void:
	var type := str(enemy.get("type", "zombie"))
	enemy["hit_flash"] = max(0.0, float(enemy.get("hit_flash", 0.0)) - delta * 7.5)
	var to_player: Vector2 = player["pos"] - enemy["pos"]
	var distance: float = max(1.0, to_player.length())
	var direction: Vector2 = to_player / distance

	if type == "thrower":
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
		if type == "boss":
			strength = 28.0
		elif type == "elite_zombie":
			strength = 44.0
		elif type == "spider":
			strength = 88.0
		var separated_pos := pos + separation.limit_length(1.0) * strength * delta
		separated_pos.x = clamp(separated_pos.x, -60.0, WORLD_SIZE.x + 60.0)
		separated_pos.y = clamp(separated_pos.y, -60.0, WORLD_SIZE.y + 60.0)
		enemy["pos"] = separated_pos


func _throw_enemy_rock(enemy: Dictionary, direction: Vector2) -> void:
	var origin: Vector2 = enemy["pos"]
	enemy_projectiles.append({
		"pos": origin + direction * (float(enemy["radius"]) + 8.0),
		"velocity": direction * 285.0,
		"radius": 7.0,
		"damage": 7.0,
		"life": 3.0,
		"color": Color("#c7b08a"),
	})
	_add_spark(origin, Color("#c7b08a"), 5)


func _hurt_enemy(enemy: Dictionary, damage: float, hit_pos: Vector2, armor_pierce: float = 0.0, push_direction: Vector2 = Vector2.ZERO, feedback: String = "hit") -> void:
	debug_hurt_events += 1
	var hp_before := float(enemy.get("hp", 0.0))
	var effective_armor = max(0.0, float(enemy.get("armor", 0.0)) - armor_pierce)
	var final_damage = max(1.0, damage - effective_armor)
	enemy["hp"] = hp_before - final_damage
	if str(enemy.get("type", "")) == "boss":
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
		"thrower":
			multiplier = 0.85
		"elite_zombie":
			multiplier = 0.45
		"boss":
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
	var ore_count := int(ceil(enemy["ore"] * ore_multiplier))
	if ore_count > 0 and randf() > float(enemy.get("ore_chance", 1.0)):
		ore_count = 0
	for i in range(ore_count):
		pickups.append({
			"pos": enemy["pos"] + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
			"radius": 6.0,
			"type": "ore",
			"value": 1,
			"color": Color("#e6b85c"),
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
			if item["type"] == "ore":
				var value := int(item.get("value", 0))
				ore += value
				round_ore_earned += value
				run_ore_collected += value
			else:
				_add_xp(item["value"] * xp_multiplier)
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
		"fire_type": template["fire_type"],
		"level": 1,
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
	_show_choice_overlay("레벨 %d" % level, "보상 선택", _sample_array(stat_rewards, 3), "_choose_reward")


func _choose_reward(reward: Dictionary) -> void:
	match reward["id"]:
		"hp":
			player["max_hp"] += 18.0
			player["hp"] = min(player["max_hp"], player["hp"] + 24.0)
		"speed":
			player["speed"] *= 1.12
		"magnet":
			player["pickup_range"] *= 1.34
		"damage":
			damage_multiplier *= 1.16
		"cooldown":
			cooldown_multiplier *= 0.86
		"ore":
			ore_multiplier *= 1.4
		"armor":
			player["armor"] += 2.0
		"xp":
			xp_multiplier *= 1.2
	_hide_overlay()
	mode = MODE_PLAY
	_render_weapons()


func _finish_round() -> void:
	if mode != MODE_PLAY:
		return
	rounds_cleared += 1
	_collect_leftover_ore()
	_award_round_clear_ore()
	_clear_combat_state()
	_fully_heal_player()
	spawn_timer = 0.0
	screen_shake = 0.0

	if wave >= MAX_ROUNDS:
		_victory()
	else:
		_open_relic_choice()


func _collect_leftover_ore() -> void:
	for item in pickups:
		if item["type"] == "ore":
			var value := int(item.get("value", 0))
			ore += value
			round_ore_earned += value
			run_ore_collected += value
	pickups.clear()


func _award_round_clear_ore() -> void:
	var base_reward := ROUND_CLEAR_ORE_BASE + wave * ROUND_CLEAR_ORE_STEP
	var reward := int(round(float(base_reward) * _relic_clear_ore_multiplier()))
	reward += 10 * _relic_count("twin_excavation_seal")
	ore += reward
	round_ore_earned += reward
	run_ore_collected += reward


func _clear_combat_state() -> void:
	enemies.clear()
	bullets.clear()
	enemy_projectiles.clear()
	pickups.clear()
	spawn_warnings.clear()


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
	match round_index:
		2:
			return "색이 다른 빠른 좀비가 합류합니다. 거리를 더 자주 다시 잡아야 합니다."
		3:
			return "체력은 낮지만 4-5마리씩 몰려오는 거미떼가 합류합니다."
		4:
			return "원거리에서 돌을 던지는 좀비가 합류합니다. 투사체와 우선 처치 대상을 읽어야 합니다."
		5:
			return "방어력이 높은 보스 좀비가 등장합니다. 보스를 처치하면 P2 테스트가 끝납니다."
		_:
			return "다음 라운드를 시작합니다."


func _open_relic_choice() -> void:
	mode = MODE_CHOICE
	var options := _roll_relic_options()
	_show_choice_overlay("라운드 %d 완료  +%d 광석" % [wave, round_ore_earned], "발견한 유물 선택", options, "_choose_relic_option")


func _choose_relic_option(relic: Dictionary) -> void:
	if str(relic.get("kind", "")) != "relic":
		return
	_add_relic(relic)
	_open_shop()


func _roll_relic_options() -> Array:
	var candidates := relic_catalog.duplicate(true)
	candidates.shuffle()
	candidates.sort_custom(func(a, b): return _relic_seen_count(a) < _relic_seen_count(b))

	var rolled: Array = []
	for relic in candidates:
		if rolled.size() >= RELIC_OPTION_COUNT:
			break
		rolled.append(relic.duplicate(true))
	_record_relic_seen(rolled)
	return rolled


func _add_relic(relic: Dictionary) -> void:
	if relic.is_empty():
		return
	var id := str(relic.get("id", ""))
	if id.is_empty():
		return
	active_relics.append(relic.duplicate(true))
	relic_counts[id] = _relic_count(id) + 1


func _open_shop() -> void:
	mode = MODE_CHOICE
	_fully_heal_player()
	shop_visit_seen_item_ids.clear()
	reroll_cost = _shop_reroll_cost()
	shop_stock = _roll_shop_stock()
	_show_shop_overlay()


func _show_shop_overlay() -> void:
	var options := shop_stock.duplicate(true)
	options.append({"id": "reroll", "kind": "command", "name": "재고 새로고침", "desc": "상점 선택지를 다시 뽑습니다.", "cost": reroll_cost})
	options.append({"id": "next_round", "kind": "command", "name": "다음 라운드", "desc": "구매를 마치고 라운드 %d을 시작합니다." % (wave + 1), "cost": 0})
	_show_choice_overlay("라운드 %d 완료  +%d 광석" % [wave, round_ore_earned], "상점 - 광석 %d" % ore, options, "_choose_shop_option")


func _roll_shop_stock(avoid_ids: Array = []) -> Array:
	var rolled: Array = []
	var next_round: int = min(wave + 1, MAX_ROUNDS)
	var counter_pool: Array = _shop_items_for_round(next_round, avoid_ids)
	if counter_pool.is_empty() and avoid_ids.is_empty():
		counter_pool = _shop_items_for_round(next_round)
	if not counter_pool.is_empty():
		rolled.append(_least_seen_shop_item(counter_pool).duplicate(true))

	var bonus_pool: Array = _relic_bonus_shop_items(avoid_ids)
	bonus_pool.shuffle()
	bonus_pool.sort_custom(func(a, b): return _shop_seen_count(a) < _shop_seen_count(b))
	for option in bonus_pool:
		if rolled.size() >= SHOP_OPTION_COUNT:
			break
		if _stock_has_item_id(rolled, str(option.get("id", ""))):
			continue
		rolled.append(option.duplicate(true))
		break

	var candidates: Array = _available_shop_items(avoid_ids)
	candidates.shuffle()
	candidates.sort_custom(func(a, b): return _shop_seen_count(a) < _shop_seen_count(b))
	for option in candidates:
		if rolled.size() >= SHOP_OPTION_COUNT:
			break
		if _stock_has_item_id(rolled, str(option.get("id", ""))):
			continue
		rolled.append(option.duplicate(true))

	if rolled.size() < SHOP_OPTION_COUNT:
		var fallback_candidates: Array = _available_shop_items([])
		fallback_candidates.shuffle()
		fallback_candidates.sort_custom(func(a, b): return _shop_seen_count(a) < _shop_seen_count(b))
		for option in fallback_candidates:
			if rolled.size() >= SHOP_OPTION_COUNT:
				break
			if _stock_has_item_id(rolled, str(option.get("id", ""))):
				continue
			rolled.append(option.duplicate(true))

	for i in range(rolled.size()):
		var option: Dictionary = rolled[i]
		option["stock_id"] = "%s_%d_%d_%d" % [option["id"], wave, rounds_cleared, i]
		option["cost"] = _scaled_shop_cost(int(option["cost"]))
	_record_shop_seen(rolled)
	_record_shop_visit_seen(rolled)
	return rolled


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


func _relic_bonus_shop_items(avoid_ids: Array) -> Array:
	var desired_ids: Array = []
	if _relic_count("echoing_stone_heart") > 0:
		desired_ids.append("long_barrel")
		desired_ids.append("spring_boots")
	if _relic_count("unstable_blast_crystal") > 0:
		desired_ids.append("shatter_charge")
		desired_ids.append("piercing_bit")

	var pool: Array = []
	for id in desired_ids:
		var option := _shop_item_by_id(str(id))
		if option.is_empty():
			continue
		if _shop_item_can_appear(option, avoid_ids):
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


func _scaled_shop_cost(base_cost: int) -> int:
	var scale := 1.0 + float(wave - 1) * 0.075
	return int(max(1.0, round(float(base_cost) * scale * _relic_shop_discount_multiplier())))


func _choose_shop_option(item: Dictionary) -> void:
	if _choice_option_disabled(item):
		return

	if item["id"] == "next_round":
		_start_next_round()
		return

	var cost := int(item.get("cost", 0))
	if ore < cost:
		return
	ore -= cost

	if item["id"] == "reroll":
		run_ore_spent += cost
		run_rerolls += 1
		reroll_cost += 2
		var reroll_avoid_ids: Array = shop_visit_seen_item_ids.duplicate()
		for id in _current_shop_item_ids():
			if not reroll_avoid_ids.has(id):
				reroll_avoid_ids.append(id)
		shop_stock = _roll_shop_stock(reroll_avoid_ids)
		_show_shop_overlay()
		return

	var purchased := _apply_shop_purchase(item)
	if not purchased:
		ore += cost
		_show_shop_overlay()
		return
	run_ore_spent += cost
	_record_shop_purchase(item)
	_remove_shop_stock(item)
	_show_shop_overlay()
	_render_weapons()


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
		_:
			return false
	if bool(item.get("unique", false)):
		var id := str(item.get("id", ""))
		if not purchased_shop_item_ids.has(id):
			purchased_shop_item_ids.append(id)
	return true


func _apply_weapon_part_stats(stats: Dictionary, part_name: String) -> void:
	if weapons.is_empty():
		return
	var weapon: Dictionary = weapons[0]
	var mods: Array = weapon.get("mods", [])
	mods.append(part_name)
	weapon["mods"] = mods
	weapon["level"] = 1 + mods.size()
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
	if stats.has("ore_mult"):
		ore_multiplier *= float(stats["ore_mult"])
	if stats.has("xp_mult"):
		xp_multiplier *= float(stats["xp_mult"])
	if stats.has("regen_add"):
		hp_regen += float(stats["regen_add"])


func _remove_shop_stock(item: Dictionary) -> void:
	var stock_id := str(item.get("stock_id", ""))
	for i in range(shop_stock.size() - 1, -1, -1):
		if str(shop_stock[i].get("stock_id", "")) == stock_id:
			shop_stock.remove_at(i)
			return


func _start_next_round() -> void:
	wave += 1
	wave_timer = _round_duration(wave)
	spawn_timer = 0.0
	round_ore_earned = 0
	spider_relic_packs_this_wave = 0
	boss_spawned = false
	_set_paused(false)
	_clear_combat_state()
	_fully_heal_player()
	_hide_overlay()
	mode = MODE_PLAY
	_render_weapons()


func _choice_option_disabled(option: Dictionary) -> bool:
	if int(option.get("cost", 0)) > ore:
		return true
	if str(option.get("kind", "")) == "weapon":
		return not _can_add_weapon(str(option["weapon"]))
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
		return "유물: 없음"
	var parts := PackedStringArray()
	for relic in summary:
		var count := int(relic.get("count", 1))
		var suffix := "" if count <= 1 else " x%d" % count
		parts.append("%s%s" % [str(relic.get("name", "")), suffix])
	return "유물: %s" % ", ".join(parts)


func _record_shop_purchase(item: Dictionary) -> void:
	run_purchase_count += 1
	run_purchase_names.append(str(item.get("name", "미확인 구매")))


func _record_enemy_defeat(type: String) -> void:
	run_kill_count += 1
	run_kills_by_type[type] = int(run_kills_by_type.get(type, 0)) + 1
	if type == "boss":
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
	lines.append("광석 획득 %d / 사용 %d / 보유 %d / 리롤 %d" % [run_ore_collected, run_ore_spent, ore, run_rerolls])
	lines.append("구매 %d회: %s" % [run_purchase_count, _format_name_counts(run_purchase_names, "없음")])
	lines.append("유물: %s" % _format_relic_counts_for_report())
	lines.append("전투 처치 %d (%s) / 보스 피해 %d / 보스 %s" % [
		run_kill_count,
		_format_kill_counts_for_report(),
		int(round(run_boss_damage)),
		"처치" if run_boss_defeated else "미처치",
	])
	return lines


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
		if count <= 1:
			parts.append(str(relic.get("name", "")))
		else:
			parts.append("%s x%d" % [str(relic.get("name", "")), count])
	return ", ".join(parts)


func _format_kill_counts_for_report() -> String:
	if run_kills_by_type.is_empty():
		return "없음"
	var parts := PackedStringArray()
	var order := ["zombie", "fast_zombie", "spider", "thrower", "elite_zombie", "boss"]
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
		"elite_zombie":
			return "엘리트"
		"boss":
			return "보스"
		_:
			return type


func _relic_enemy_density_multiplier() -> float:
	return 1.0 + 0.15 * float(_relic_count("red_vein_sample"))


func _relic_spawn_interval_multiplier() -> float:
	return max(0.58, 1.0 - 0.08 * float(_relic_count("red_vein_sample")))


func _relic_enemy_hp_multiplier() -> float:
	return float(pow(1.10, _relic_count("black_shell")))


func _relic_enemy_speed_multiplier() -> float:
	return float(pow(1.08, _relic_count("hungry_lantern")))


func _relic_thrower_cooldown_multiplier() -> float:
	return float(pow(0.86, _relic_count("echoing_stone_heart")))


func _relic_ore_drop_bonus() -> float:
	return min(0.45, 0.10 * float(_relic_count("red_vein_sample")))


func _relic_clear_ore_multiplier() -> float:
	return 1.0 + 0.20 * float(_relic_count("spider_egg_fossil"))


func _relic_shop_discount_multiplier() -> float:
	return max(0.55, 1.0 - 0.10 * float(_relic_count("black_shell")))


func _should_spawn_elite_zombie() -> bool:
	var count := _relic_count("twin_excavation_seal")
	if count <= 0 or wave < 2:
		return false
	if enemies.size() >= _enemy_cap():
		return false
	var chance: float = min(0.22, 0.045 * float(count))
	if wave >= MAX_ROUNDS:
		chance *= 0.65
	return randf() < chance


func _trigger_relic_death_hazard(enemy: Dictionary) -> void:
	var count := _relic_count("unstable_blast_crystal")
	if count <= 0 or str(enemy.get("type", "")) == "boss":
		return

	var pos: Vector2 = enemy["pos"]
	var radius: float = 42.0 + 8.0 * float(count)
	var color := Color("#f0643b")
	sparks.append({
		"line": false,
		"pos": pos,
		"velocity": Vector2.ZERO,
		"life": 0.22,
		"max_life": 0.22,
		"color": color,
		"radius": radius,
		"ring": true,
	})
	_add_spark(pos, color, 12)

	if player["pos"].distance_to(pos) > radius or player["hurt_cooldown"] > 0.0:
		return

	var damage: float = max(1.0, 5.0 + 2.0 * float(count) - player["armor"] * 0.5)
	player["hp"] -= damage
	player["hurt_cooldown"] = 0.38
	screen_shake = max(screen_shake, 0.95)
	_add_floating_text("폭발 -%d" % int(round(damage)), player["pos"] + Vector2(0, -34), color)


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
		if kind == "boss":
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
		elif type == "boss":
			draw_circle(pos, radius + 5.0, Color("#3f324b"))
			draw_circle(pos, radius, enemy["color"])
			draw_arc(pos, radius + 8.0, 0.0, TAU, 72, Color("#c7b08a"), 4.0)
			draw_circle(pos + Vector2(-radius * 0.18, -radius * 0.16), radius * 0.26, Color("#221a28"))
		else:
			draw_circle(pos, radius, enemy["color"])
			draw_circle(pos + Vector2(-radius * 0.25, -radius * 0.2), radius * 0.35, Color(0, 0, 0, 0.28))
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


func _enemy_has_sprite_asset(type: String) -> bool:
	return type == "zombie" or type == "fast_zombie" or type == "spider" or type == "thrower" or type == "elite_zombie" or type == "boss"


func _draw_enemy_asset_sprite(enemy: Dictionary) -> bool:
	var type := str(enemy.get("type", "zombie"))
	match type:
		"zombie":
			_draw_single_image_enemy_sprite(enemy, zombie_idle_texture, ZOMBIE_VISUAL_SCALE, ZOMBIE_MOVE_PERIOD, 6.5, 3.4, 5.2, 0.038, Vector2(25, 5), 29.0)
			return true
		"fast_zombie":
			_draw_single_image_enemy_sprite(enemy, fast_zombie_texture, 0.225, 0.46, 8.5, 5.2, 7.0, 0.058, Vector2(23, 4.5), 28.0)
			return true
		"spider":
			_draw_single_image_enemy_sprite(enemy, spider_swarm_texture, 0.175, 0.42, 3.2, 2.0, 3.0, 0.028, Vector2(20, 4), 20.0)
			return true
		"thrower":
			_draw_single_image_enemy_sprite(enemy, thrower_zombie_texture, 0.265, 0.88, 4.5, 2.2, 3.2, 0.024, Vector2(27, 5), 30.0)
			return true
		"elite_zombie":
			_draw_single_image_enemy_sprite(enemy, zombie_idle_texture, 0.34, 0.92, 5.2, 2.8, 3.4, 0.026, Vector2(36, 7), 42.0)
			return true
		"boss":
			_draw_single_image_enemy_sprite(enemy, boss_zombie_texture, 0.44, 1.18, 3.0, 2.0, 2.1, 0.018, Vector2(48, 9), 52.0)
			return true
	return false


func _draw_single_image_enemy_sprite(
	enemy: Dictionary,
	texture: Texture2D,
	base_scale: float,
	period: float,
	lateral_amount: float,
	hop_amount: float,
	rotation_amount: float,
	squash_amount: float,
	shadow_size: Vector2,
	shadow_y: float
) -> void:
	var ground_pos: Vector2 = enemy["pos"]
	var pos := _enemy_draw_pos(enemy)
	var faces_right := player.has("pos") and float(player["pos"].x) > ground_pos.x
	var sign := 1.0 if faces_right else -1.0
	var phase := fposmod(elapsed + float(enemy["id"]) * 0.11, period) / period * TAU
	var step := sin(phase)
	var hop := absf(step)
	var drag := cos(phase)
	var lurch := sin(phase + PI * 0.22)
	var local_pos := Vector2(lateral_amount * drag, -hop_amount * hop + 1.2 * lurch)
	var local_rot := deg_to_rad(-rotation_amount * drag + 1.4 * lurch)
	var local_scale := Vector2(1.0 + squash_amount * hop, 1.0 - squash_amount * 1.16 * hop)
	var hp: float = enemy["hp"]
	var max_hp: float = enemy["max_hp"]
	var flash: float = 1.0 - clamp(hp / max_hp, 0.0, 1.0)
	var modulate := Color(1.0, 1.0 - flash * 0.18, 1.0 - flash * 0.18)
	var hit_flash: float = clamp(float(enemy.get("hit_flash", 0.0)), 0.0, 1.0)
	if hit_flash > 0.0:
		var hit_color: Color = enemy.get("hit_flash_color", Color("#f5efe3"))
		modulate = modulate.lerp(hit_color, hit_flash * 0.54)

	_draw_ellipse_shadow(ground_pos + Vector2(0, shadow_y), shadow_size + Vector2(4.0 * hop, 1.5 * hop), Color(0, 0, 0, 0.18))
	_draw_sprite_part(texture, pos, local_pos, sign, local_rot, local_scale, base_scale, modulate)


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
		"elite_zombie":
			return 58.0
		"boss":
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
		"elite_zombie":
			return -63.0
		"boss":
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
		else:
			if bool(bullet.get("splash_feedback", false)):
				var splash_color := Color("#f0643b")
				splash_color.a = 0.20
				draw_circle(bullet["pos"], float(bullet["radius"]) * 2.3, splash_color)
			draw_circle(bullet["pos"], bullet["radius"], bullet["color"])


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
		var points := PackedVector2Array([
			pos + Vector2(0, -radius),
			pos + Vector2(radius, 0),
			pos + Vector2(0, radius),
			pos + Vector2(-radius, 0),
		])
		draw_colored_polygon(points, item["color"])


func _draw_sparks() -> void:
	for spark in sparks:
		var alpha = clamp(spark["life"] / spark["max_life"], 0.0, 1.0)
		var color: Color = spark["color"]
		color.a = alpha
		if spark.get("line", false):
			draw_line(spark["from"], spark["to"], color, float(spark.get("width", 3.0)))
		elif spark.get("ring", false):
			draw_arc(spark["pos"], float(spark.get("radius", 30.0)) * (1.0 - alpha * 0.2), 0.0, TAU, 48, color, float(spark.get("width", 3.0)))
		else:
			draw_circle(spark["pos"], float(spark.get("size", 3.0)), color)


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
		"P3 광맥 투기장",
		"5라운드 동안 유물을 골라 위험을 누적시키고, 상점에서 드릴촉 부품을 붙여 대응하세요.",
		"탐사 시작"
	)


func _show_choice_overlay(eyebrow_text: String, title_text: String, options: Array, method_name: String) -> void:
	active_choice_options = options
	active_choice_method = method_name
	game_ui.show_choice(eyebrow_text, title_text, _decorate_choice_options(options), _active_relic_summary(), _current_state_summary())


func _show_game_over_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_end(
		"탐사 종료",
		"P4 런 리포트",
		_run_report_text(),
		"다시 도전",
		_active_relic_summary()
	)


func _show_victory_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_end(
		"탐사 완료",
		"P4 런 리포트",
		_run_report_text(),
		"다시 시작",
		_active_relic_summary()
	)


func _start_run() -> void:
	_reset_run(true)
	_hide_overlay()


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
		"ore": ore,
		"time": _format_time(max(0.0, wave_timer)),
		"relics": _active_relic_summary(),
	})


func _current_state_summary() -> Dictionary:
	var weapon_lines := PackedStringArray()
	for weapon in weapons:
		var mods: Array = weapon.get("mods", [])
		var mod_names := PackedStringArray()
		for mod_name in mods:
			mod_names.append(str(mod_name))
		var mod_text := "부품 없음" if mod_names.is_empty() else ", ".join(mod_names)
		weapon_lines.append("%s · 피해 %d · %s" % [
			str(weapon.get("name", "무기")),
			int(round(float(weapon.get("damage", 0.0)) * damage_multiplier)),
			mod_text,
		])
	if weapon_lines.is_empty():
		weapon_lines.append("무기 없음")

	var lines := PackedStringArray()
	lines.append("체력 %d/%d · 광석 %d · 공세 %d/%d · 남은 시간 %s" % [
		int(round(float(player.get("hp", 0.0)))),
		int(round(float(player.get("max_hp", 100.0)))),
		ore,
		wave,
		MAX_ROUNDS,
		_format_time(max(0.0, wave_timer)),
	])
	lines.append("무기: %s" % " / ".join(weapon_lines))
	lines.append("유물: %s" % _format_relic_counts_for_report())
	lines.append("처치 %d · 구매 %d · 리롤 %d" % [run_kill_count, run_purchase_count, run_rerolls])
	return {"lines": lines}


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
	if disabled and str(option.get("kind", "")) == "weapon":
		return "무기 슬롯 또는 강화 한도 초과"
	if str(option.get("kind", "")) == "relic":
		return "%s · %s" % [str(option.get("danger", "위험 누적")), str(option.get("reward", "보상 누적"))]
	if option.has("cost"):
		var cost := int(option["cost"])
		var price_text := "무료" if cost <= 0 else "광석 %d" % cost
		if option.has("counter"):
			return "%s · %s" % [str(option["counter"]), price_text]
		if cost <= 0:
			return "무료"
		return price_text
	if option.has("tag"):
		return str(option["tag"])
	return ""


func _on_ui_option_selected(option: Dictionary) -> void:
	if active_choice_method.is_empty():
		return
	Callable(self, active_choice_method).call(option)
