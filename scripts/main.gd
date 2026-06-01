extends Node2D

const GameUIScript = preload("res://scripts/ui/game_ui.gd")
const OreUIThemeScript = preload("res://scripts/ui/ore_ui_theme.gd")

const WORLD_SIZE := Vector2(1280, 720)
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
const P1_ROUND_DURATION := 42.0
const P1_BOSS_ROUND_DURATION := 120.0
const P1_REWARDS_ENABLED := false
const SMOKE_ROUND_DURATION := 5.0
const SMOKE_PLAYTEST_DURATION := 70.0
const SMOKE_PLAYTEST_CAPTURE_PATH := "/private/tmp/orebound-godot-playtest.png"
const CHOICE_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-choice-ui.png"
const SHOP_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-shop-ui.png"
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
var next_enemy_id := 1
var reroll_cost := 2
var round_ore_earned := 0
var rounds_cleared := 0

var player := {}
var weapons: Array = []
var items: Array = []
var shop_stock: Array = []
var enemies: Array = []
var bullets: Array = []
var enemy_projectiles: Array = []
var pickups: Array = []
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
	{"id": "w_spitter", "kind": "weapon", "weapon": "spitter", "name": "광석 분사기", "desc": "균형 잡힌 단발 자동 무기입니다. 같은 무기는 4단계까지 강화됩니다.", "cost": 18},
	{"id": "w_flintlock", "kind": "weapon", "weapon": "flintlock", "name": "쌍발 화승총", "desc": "짧은 재사용 대기시간으로 두 발을 흩뿌립니다.", "cost": 20},
	{"id": "w_drill", "kind": "weapon", "weapon": "drill", "name": "파편 드릴", "desc": "느리지만 강한 관통탄을 발사합니다.", "cost": 28},
	{"id": "w_coil", "kind": "weapon", "weapon": "coil", "name": "전류 코일", "desc": "근처 적 여럿에게 전류가 튑니다.", "cost": 32},
	{"id": "w_cleaver", "kind": "weapon", "weapon": "cleaver", "name": "녹슨 절단기", "desc": "가까운 적들을 크게 베어냅니다.", "cost": 24},
	{"id": "w_launcher", "kind": "weapon", "weapon": "launcher", "name": "광산 유탄기", "desc": "폭발탄으로 작은 무리를 지웁니다.", "cost": 36},
	{"id": "rations", "kind": "heal", "name": "야전 식량", "desc": "체력 35 회복.", "cost": 14},
	{"id": "barrel", "kind": "item", "name": "강화 총열", "desc": "+12% 무기 피해.", "cost": 22, "stats": {"damage_mult": 1.12}},
	{"id": "pocket_magnet", "kind": "item", "name": "휴대 자석", "desc": "+24% 획득 범위.", "cost": 16, "stats": {"pickup_mult": 1.24}},
	{"id": "tactical_glove", "kind": "item", "name": "전술 장갑", "desc": "+10% 공격 속도, -3% 피해.", "cost": 18, "stats": {"cooldown_mult": 0.90, "damage_mult": 0.97}},
	{"id": "rangefinder", "kind": "item", "name": "거리 측정기", "desc": "+18% 사거리.", "cost": 18, "stats": {"range_mult": 1.18}},
	{"id": "iron_plate", "kind": "item", "name": "철판 조끼", "desc": "+3 방어, -5% 이동 속도.", "cost": 24, "stats": {"armor_add": 3.0, "speed_mult": 0.95}},
	{"id": "glass_core", "kind": "item", "name": "유리 심장", "desc": "+22% 피해, -12 최대 체력.", "cost": 28, "stats": {"damage_mult": 1.22, "max_hp_add": -12.0}},
	{"id": "harvester", "kind": "item", "name": "수확 부품", "desc": "+28% 광석 획득.", "cost": 25, "stats": {"ore_mult": 1.28}},
	{"id": "survey_map", "kind": "item", "name": "측량 지도", "desc": "+24% 경험치 획득.", "cost": 20, "stats": {"xp_mult": 1.24}},
	{"id": "spring_gear", "kind": "item", "name": "스프링 기어", "desc": "+11% 이동 속도.", "cost": 17, "stats": {"speed_mult": 1.11}},
	{"id": "vita_pump", "kind": "item", "name": "생체 펌프", "desc": "+10 최대 체력, 초당 체력 재생 +0.35.", "cost": 26, "stats": {"max_hp_add": 10.0, "regen_add": 0.35}},
]

var weapon_catalog := {
	"spitter": {"name": "광석 분사기", "fire_type": "bullet", "cooldown": 0.62, "damage": 18.0, "range": 470.0, "speed": 640.0, "color": Color("#e6b85c"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"flintlock": {"name": "쌍발 화승총", "fire_type": "bullet", "cooldown": 0.54, "damage": 9.0, "range": 390.0, "speed": 760.0, "color": Color("#f0643b"), "pierce": 0, "projectiles": 2, "spread": 0.20, "splash": 0.0},
	"drill": {"name": "파편 드릴", "fire_type": "bullet", "cooldown": 1.28, "damage": 34.0, "range": 560.0, "speed": 500.0, "color": Color("#93c96d"), "pierce": 3, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"coil": {"name": "전류 코일", "fire_type": "arc", "cooldown": 1.08, "damage": 16.0, "range": 180.0, "speed": 0.0, "color": Color("#6cc3c0"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"cleaver": {"name": "녹슨 절단기", "fire_type": "slash", "cooldown": 0.86, "damage": 23.0, "range": 132.0, "speed": 0.0, "color": Color("#d8ceb9"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"launcher": {"name": "광산 유탄기", "fire_type": "explosive", "cooldown": 1.48, "damage": 26.0, "range": 520.0, "speed": 430.0, "color": Color("#d87745"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 72.0},
}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--smoke-playtest") or args.has("--capture-choice-ui") or args.has("--capture-shop-ui") or args.has("--capture-stage1") or args.has("--capture-monster-roster"):
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
	elif args.has("--capture-stage1"):
		_capture_stage1_and_quit.call_deferred()
	elif args.has("--capture-monster-roster"):
		_capture_monster_roster_and_quit.call_deferred()
	elif args.has("--smoke-playtest"):
		_start_smoke_playtest.call_deferred()


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
	_open_shop()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(SHOP_UI_CAPTURE_PATH)
	get_tree().quit()


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
		paused = not paused
		if game_ui != null:
			game_ui.set_paused(paused)
	if event.is_action_pressed("dash") and mode == MODE_PLAY and dash_cooldown <= 0.0:
		player["dash_time"] = 0.16
		dash_cooldown = 1.7


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
		game_ui.set_paused(false)
	next_enemy_id = 1
	reroll_cost = _shop_reroll_cost()
	round_ore_earned = 0
	rounds_cleared = 0
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
	enemies.clear()
	bullets.clear()
	enemy_projectiles.clear()
	pickups.clear()
	sparks.clear()
	floating_text.clear()
	boss_spawned = false
	_add_weapon("spitter")
	_render_weapons()


func _round_duration(round_index: int) -> float:
	if smoke_playtest:
		return SMOKE_ROUND_DURATION
	if round_index >= MAX_ROUNDS:
		return P1_BOSS_ROUND_DURATION
	return P1_ROUND_DURATION


func _shop_reroll_cost() -> int:
	return max(2, int(round(2.0 + wave * 0.65 + rounds_cleared * 0.25)))


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
	_spawn_enemies()
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
	print("SMOKE_PLAYTEST result=%s mode=%s wave=%d level=%d hp=%.1f ore=%d enemies=%d pickups=%d choices=%d elapsed=%.2f capture=%s" % [
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
	])
	get_tree().quit(1 if result == "GAME_OVER" or result == "TIMEOUT" else 0)


func _spawn_enemies() -> void:
	if (wave < MAX_ROUNDS and wave_timer <= 0.0) or spawn_timer > 0.0:
		return

	if wave >= MAX_ROUNDS and not boss_spawned:
		enemies.append(_make_enemy("boss"))
		boss_spawned = true
		spawn_timer = 1.8
		return

	if enemies.size() >= _enemy_cap():
		spawn_timer = 0.35
		return

	var kind := _pick_enemy_kind()
	var pack_size := _enemy_pack_size(kind)
	_spawn_enemy_pack(kind, pack_size)
	spawn_timer = _enemy_spawn_interval(kind)


func _spawn_enemy_pack(kind: String, pack_size: int) -> void:
	var anchor := _spawn_position()
	for i in range(pack_size):
		if enemies.size() >= _enemy_cap():
			return
		var enemy := _make_enemy(kind)
		enemy["pos"] = anchor + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))
		enemies.append(enemy)


func _enemy_cap() -> int:
	match wave:
		1:
			return 14
		2:
			return 18
		3:
			return 24
		4:
			return 26
		_:
			return 12


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


func _make_enemy(kind: String) -> Dictionary:
	var hp := 24.0
	var radius: float = 16.0
	var speed := 108.0
	var damage: float = 9.0
	var color := Color("#b95b4b")
	var armor := 0.0
	var dropped_ore := 0
	var dropped_xp := 0
	var desired_range := 0.0
	var attack_cooldown := 0.0

	match kind:
		"fast_zombie":
			hp = 20.0
			radius = 14.0
			speed = 166.0
			damage = 7.0
			color = Color("#d68149")
		"spider":
			hp = 8.0
			radius = 9.0
			speed = 142.0
			damage = 4.0
			color = Color("#6f9f61")
		"thrower":
			hp = 36.0
			radius = 18.0
			speed = 76.0
			damage = 6.0
			color = Color("#7e8a76")
			desired_range = 360.0
			attack_cooldown = 2.15
		"boss":
			hp = 380.0
			radius = 42.0
			speed = 54.0
			damage = 16.0
			armor = 3.0
			color = Color("#6f4f86")
		_:
			kind = "zombie"

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
		"xp": dropped_xp,
		"desired_range": desired_range,
		"attack_timer": randf_range(0.25, max(0.35, attack_cooldown)),
		"attack_cooldown": attack_cooldown,
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
	var best := {}
	var best_distance := search_range * search_range
	for enemy in enemies:
		var distance: float = player["pos"].distance_squared_to(enemy["pos"])
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


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
			"pierce": weapon["pierce"],
			"splash": float(weapon.get("splash", 0.0)) if explosive else 0.0,
			"hit_ids": [],
		})
	_add_spark(origin, weapon["color"], 6)


func _fire_arc(weapon: Dictionary, effective_range: float) -> void:
	var targets := []
	for enemy in enemies:
		if player["pos"].distance_squared_to(enemy["pos"]) <= effective_range * effective_range:
			targets.append(enemy)
	targets.sort_custom(func(a, b): return player["pos"].distance_squared_to(a["pos"]) < player["pos"].distance_squared_to(b["pos"]))

	var count = min(4, targets.size())
	for i in range(count):
		var target = targets[i]
		_hurt_enemy(target, weapon["damage"] * damage_multiplier, target["pos"])
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
		if player["pos"].distance_squared_to(enemy["pos"]) <= effective_range * effective_range:
			targets.append(enemy)
	targets.sort_custom(func(a, b): return player["pos"].distance_squared_to(a["pos"]) < player["pos"].distance_squared_to(b["pos"]))

	var count = min(5, targets.size())
	for i in range(count):
		var target = targets[i]
		_hurt_enemy(target, weapon["damage"] * damage_multiplier, target["pos"])
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
		var bullet = bullets[i]
		bullet["pos"] += bullet["velocity"] * delta
		bullet["life"] -= delta

		for enemy in enemies:
			if bullet["hit_ids"].has(enemy["id"]):
				continue
			if bullet["pos"].distance_squared_to(enemy["pos"]) <= pow(bullet["radius"] + enemy["radius"], 2.0):
				bullet["hit_ids"].append(enemy["id"])
				if float(bullet.get("splash", 0.0)) > 0.0:
					_explode_bullet(bullet, bullet["pos"])
					bullet["life"] = 0.0
					break
				else:
					_hurt_enemy(enemy, bullet["damage"], bullet["pos"])
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


func _explode_bullet(bullet: Dictionary, pos: Vector2) -> void:
	var splash := float(bullet.get("splash", 0.0))
	if splash <= 0.0:
		return
	for enemy in enemies:
		var distance := pos.distance_to(enemy["pos"])
		if distance <= splash:
			var falloff: float = 1.0 - min(0.45, distance / splash * 0.45)
			_hurt_enemy(enemy, bullet["damage"] * falloff, enemy["pos"])
	_add_spark(pos, bullet["color"], 22)
	sparks.append({
		"line": false,
		"pos": pos,
		"velocity": Vector2.ZERO,
		"life": 0.18,
		"max_life": 0.18,
		"color": bullet["color"],
		"radius": splash,
		"ring": true,
	})


func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		_update_enemy_behavior(enemy, delta)

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

		if enemy["hp"] <= 0.0:
			var defeated_type := str(enemy.get("type", "zombie"))
			_drop_pickups(enemy)
			_add_spark(enemy["pos"], enemy["color"], 14)
			enemies.remove_at(i)
			if defeated_type == "boss":
				_victory()
				return


func _update_enemy_behavior(enemy: Dictionary, delta: float) -> void:
	var type := str(enemy.get("type", "zombie"))
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

	var pos: Vector2 = enemy["pos"]
	pos.x = clamp(pos.x, -60.0, WORLD_SIZE.x + 60.0)
	pos.y = clamp(pos.y, -60.0, WORLD_SIZE.y + 60.0)
	enemy["pos"] = pos


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


func _hurt_enemy(enemy: Dictionary, damage: float, hit_pos: Vector2) -> void:
	var final_damage = max(1.0, damage - float(enemy.get("armor", 0.0)))
	enemy["hp"] -= final_damage
	_add_floating_text(str(int(round(final_damage))), hit_pos + Vector2(0, -8), Color("#f5efe3"))
	_add_spark(hit_pos, Color("#f5efe3"), 4)


func _drop_pickups(enemy: Dictionary) -> void:
	if not P1_REWARDS_ENABLED:
		return
	pickups.append({"pos": enemy["pos"], "radius": 8.0, "type": "xp", "value": enemy["xp"], "color": Color("#6cc3c0")})
	var ore_count := int(ceil(enemy["ore"] * ore_multiplier))
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
				ore += item["value"]
				round_ore_earned += item["value"]
			else:
				_add_xp(item["value"] * xp_multiplier)
			pickups.remove_at(i)


func _add_xp(amount: float) -> void:
	if not P1_REWARDS_ENABLED:
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
	_clear_combat_state()
	_fully_heal_player()
	spawn_timer = 0.0
	screen_shake = 0.0

	if wave >= MAX_ROUNDS:
		_victory()
	else:
		_open_round_break()


func _collect_leftover_ore() -> void:
	for item in pickups:
		if item["type"] == "ore":
			ore += item["value"]
			round_ore_earned += item["value"]
	pickups.clear()


func _clear_combat_state() -> void:
	enemies.clear()
	bullets.clear()
	enemy_projectiles.clear()
	pickups.clear()


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
			return "방어력이 높은 보스 좀비가 등장합니다. 보스를 처치하면 P1 테스트가 끝납니다."
		_:
			return "다음 라운드를 시작합니다."


func _open_shop() -> void:
	mode = MODE_CHOICE
	player["hp"] = min(player["max_hp"], player["hp"] + 12.0)
	reroll_cost = _shop_reroll_cost()
	shop_stock = _roll_shop_stock()
	_show_shop_overlay()


func _show_shop_overlay() -> void:
	var options := shop_stock.duplicate(true)
	options.append({"id": "reroll", "kind": "command", "name": "재고 새로고침", "desc": "상점 선택지를 다시 뽑습니다.", "cost": reroll_cost})
	options.append({"id": "next_round", "kind": "command", "name": "다음 라운드", "desc": "구매를 마치고 라운드 %d을 시작합니다." % (wave + 1), "cost": 0})
	_show_choice_overlay("라운드 %d 완료" % wave, "상점 - 광석 %d" % ore, options, "_choose_shop_option")


func _roll_shop_stock() -> Array:
	var rolled := _sample_array(shop_catalog, SHOP_OPTION_COUNT)
	for i in range(rolled.size()):
		var option: Dictionary = rolled[i]
		option["stock_id"] = "%s_%d_%d_%d" % [option["id"], wave, rounds_cleared, i]
		option["cost"] = _scaled_shop_cost(int(option["cost"]))
	return rolled


func _scaled_shop_cost(base_cost: int) -> int:
	var scale := 1.0 + float(wave - 1) * 0.075
	return int(max(1.0, round(base_cost * scale)))


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
		reroll_cost += 2
		shop_stock = _roll_shop_stock()
		_show_shop_overlay()
		return

	_apply_shop_purchase(item)
	_remove_shop_stock(item)
	_show_shop_overlay()
	_render_weapons()


func _apply_shop_purchase(item: Dictionary) -> void:
	match str(item.get("kind", "")):
		"weapon":
			if not _add_weapon(str(item["weapon"])):
				ore += int(item.get("cost", 0))
				return
		"heal":
			player["hp"] = min(player["max_hp"], player["hp"] + 35.0)
		"item":
			items.append(item["name"])
			_apply_item_stats(item.get("stats", {}))


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
	boss_spawned = false
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
	draw_set_transform(shake, 0.0, Vector2.ONE)
	_draw_ground()
	_draw_pickups()
	_draw_bullets()
	_draw_enemy_projectiles()
	_draw_enemies()
	_draw_player()
	_draw_sparks()
	_draw_floating_text()
	if paused:
		draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0, 0, 0, 0.34), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#171a15"), true)
	for x in range(0, int(WORLD_SIZE.x) + 120, 44):
		draw_line(Vector2(x, 0), Vector2(x - 120, WORLD_SIZE.y), Color(1, 0.96, 0.9, 0.045), 1.0)
	for i in range(80):
		var x := float((i * 97) % int(WORLD_SIZE.x))
		var y := float((i * 181) % int(WORLD_SIZE.y))
		draw_rect(Rect2(Vector2(x, y), Vector2(3 + i % 3, 3 + i % 4)), Color(0.9, 0.72, 0.36, 0.08), true)


func _draw_player() -> void:
	var pos: Vector2 = player["pos"]
	draw_circle(pos, player["pickup_range"], Color(0.9, 0.72, 0.36, 0.08))
	draw_arc(pos, player["pickup_range"], 0.0, TAU, 96, Color(0.9, 0.72, 0.36, 0.16), 2.0)
	_draw_player_sprite(pos)


func _draw_enemies() -> void:
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
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
		var hp_ratio = clamp(enemy["hp"] / enemy["max_hp"], 0.0, 1.0)
		var hp_width := radius * 2.0
		var hp_y := -radius - 9.0
		if _enemy_has_sprite_asset(type):
			hp_width = _enemy_asset_hp_width(type, radius)
			hp_y = _enemy_asset_hp_y(type, radius)
		draw_rect(Rect2(pos + Vector2(-hp_width * 0.5, hp_y), Vector2(hp_width, 4)), Color("#111412"), true)
		draw_rect(Rect2(pos + Vector2(-hp_width * 0.5, hp_y), Vector2(hp_width * hp_ratio, 4)), Color("#e6b85c"), true)


func _enemy_has_sprite_asset(type: String) -> bool:
	return type == "zombie" or type == "fast_zombie" or type == "spider" or type == "thrower" or type == "boss"


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
	var pos: Vector2 = enemy["pos"]
	var faces_right := player.has("pos") and float(player["pos"].x) > pos.x
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

	_draw_ellipse_shadow(pos + Vector2(0, shadow_y), shadow_size + Vector2(4.0 * hop, 1.5 * hop), Color(0, 0, 0, 0.18))
	_draw_sprite_part(texture, pos, local_pos, sign, local_rot, local_scale, base_scale, modulate)


func _enemy_asset_hp_width(type: String, radius: float) -> float:
	match type:
		"fast_zombie":
			return 38.0
		"spider":
			return 32.0
		"thrower":
			return 46.0
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
	draw_set_transform(draw_pos, rotation * facing_sign, draw_scale)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ellipse_shadow(pos: Vector2, scale: Vector2, color: Color) -> void:
	draw_set_transform(pos, 0.0, scale)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bullets() -> void:
	for bullet in bullets:
		draw_circle(bullet["pos"], bullet["radius"], bullet["color"])


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
			draw_line(spark["from"], spark["to"], color, 3.0)
		elif spark.get("ring", false):
			draw_arc(spark["pos"], float(spark.get("radius", 30.0)) * (1.0 - alpha * 0.2), 0.0, TAU, 48, color, 3.0)
		else:
			draw_circle(spark["pos"], 3.0, color)


func _draw_floating_text() -> void:
	for text in floating_text:
		var color: Color = text["color"]
		color.a = clamp(text["life"] / 0.55, 0.0, 1.0)
		draw_string(ui_font, text["pos"], text["text"], HORIZONTAL_ALIGNMENT_CENTER, -1.0, 16, color)


func _build_ui() -> void:
	game_ui = GameUIScript.new()
	add_child(game_ui)
	game_ui.setup(ui_font)
	game_ui.start_requested.connect(_start_run)
	game_ui.option_selected.connect(_on_ui_option_selected)


func _show_start_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_start(
		"봉인된 채굴지",
		"P1 광맥 투기장",
		"5라운드 동안 새 적 패턴을 버티고, 마지막 보스 좀비를 쓰러뜨리면 테스트가 끝납니다.",
		"탐사 시작"
	)


func _show_choice_overlay(eyebrow_text: String, title_text: String, options: Array, method_name: String) -> void:
	active_choice_options = options
	active_choice_method = method_name
	game_ui.show_choice(eyebrow_text, title_text, _decorate_choice_options(options))


func _show_game_over_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_end(
		"탐사 종료",
		"압도당했습니다",
		"라운드 %d/%d 레벨 %d 광석 %d 생존 시간 %s" % [wave, MAX_ROUNDS, level, ore, _format_time(elapsed)],
		"다시 도전"
	)


func _show_victory_overlay() -> void:
	active_choice_options = []
	active_choice_method = ""
	game_ui.show_end(
		"탐사 완료",
		"P1 보스 처치",
		"5라운드 전투 루프를 완주했습니다. 기본 좀비, 빠른 좀비, 거미떼, 투척 좀비, 보스 좀비 패턴을 모두 통과했습니다.",
		"다시 시작"
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
	})


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
	if option.has("cost"):
		var cost := int(option["cost"])
		if cost <= 0:
			return "무료"
		return "광석 %d" % cost
	if option.has("tag"):
		return str(option["tag"])
	return ""


func _on_ui_option_selected(option: Dictionary) -> void:
	if active_choice_method.is_empty():
		return
	Callable(self, active_choice_method).call(option)
