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
const MAX_ROUNDS := 20
const MAX_WEAPON_SLOTS := 6
const MAX_WEAPON_LEVEL := 4
const SHOP_OPTION_COUNT := 4
const BASE_ROUND_DURATION := 24.0
const MAX_ROUND_DURATION := 62.0
const SMOKE_ROUND_DURATION := 8.0
const SMOKE_PLAYTEST_DURATION := 18.0
const SMOKE_PLAYTEST_CAPTURE_PATH := "/private/tmp/orebound-godot-playtest.png"
const CHOICE_UI_CAPTURE_PATH := "/private/tmp/orebound-godot-choice-ui.png"

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
var pickups: Array = []
var sparks: Array = []
var floating_text: Array = []

var game_ui: CanvasLayer
var ui_font: Font
var active_choice_options: Array = []
var active_choice_method := ""
var smoke_playtest := false
var smoke_elapsed := 0.0
var smoke_choices_taken := 0
var smoke_finishing := false

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
	"spitter": {"name": "광석 분사기", "fire_type": "bullet", "cooldown": 0.72, "damage": 14.0, "range": 470.0, "speed": 640.0, "color": Color("#e6b85c"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"flintlock": {"name": "쌍발 화승총", "fire_type": "bullet", "cooldown": 0.54, "damage": 9.0, "range": 390.0, "speed": 760.0, "color": Color("#f0643b"), "pierce": 0, "projectiles": 2, "spread": 0.20, "splash": 0.0},
	"drill": {"name": "파편 드릴", "fire_type": "bullet", "cooldown": 1.28, "damage": 34.0, "range": 560.0, "speed": 500.0, "color": Color("#93c96d"), "pierce": 3, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"coil": {"name": "전류 코일", "fire_type": "arc", "cooldown": 1.08, "damage": 16.0, "range": 180.0, "speed": 0.0, "color": Color("#6cc3c0"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"cleaver": {"name": "녹슨 절단기", "fire_type": "slash", "cooldown": 0.86, "damage": 23.0, "range": 132.0, "speed": 0.0, "color": Color("#d8ceb9"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 0.0},
	"launcher": {"name": "광산 유탄기", "fire_type": "explosive", "cooldown": 1.48, "damage": 26.0, "range": 520.0, "speed": 430.0, "color": Color("#d87745"), "pierce": 0, "projectiles": 1, "spread": 0.0, "splash": 72.0},
}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--smoke-playtest") or args.has("--capture-choice-ui"):
		seed(12345)
	else:
		randomize()
	ui_font = OreUIThemeScript.load_font()
	_build_ui()
	_reset_run(false)
	_show_start_overlay()
	if args.has("--capture-ui"):
		_capture_ui_and_quit.call_deferred()
	elif args.has("--capture-choice-ui"):
		_capture_choice_ui_and_quit.call_deferred()
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
	}
	weapons.clear()
	items.clear()
	shop_stock.clear()
	enemies.clear()
	bullets.clear()
	pickups.clear()
	sparks.clear()
	floating_text.clear()
	_add_weapon("spitter")
	_render_weapons()


func _round_duration(round_index: int) -> float:
	if smoke_playtest:
		return SMOKE_ROUND_DURATION
	return min(MAX_ROUND_DURATION, BASE_ROUND_DURATION + round_index * 2.0)


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
	_update_enemies(delta)
	_update_pickups(delta)
	_update_sparks(delta)
	_update_floating_text(delta)

	if wave_timer <= 0.0:
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


func _start_smoke_playtest() -> void:
	smoke_playtest = true
	smoke_elapsed = 0.0
	smoke_choices_taken = 0
	smoke_finishing = false
	_start_run()


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
		_finish_smoke_playtest.call_deferred("OK")


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
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(SMOKE_PLAYTEST_CAPTURE_PATH)
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
		SMOKE_PLAYTEST_CAPTURE_PATH,
	])
	get_tree().quit(1 if result == "GAME_OVER" else 0)


func _spawn_enemies() -> void:
	if wave_timer <= 0.0 or spawn_timer > 0.0:
		return
	var wave_pressure = min(0.28, wave * 0.018)
	spawn_timer = max(0.22, 1.05 - wave_pressure - elapsed * 0.0014)
	var pack_size := 1 + int(floor(wave / 3.0))
	if randf() < wave * 0.06:
		pack_size += 1
	for i in range(pack_size):
		enemies.append(_make_enemy())


func _make_enemy() -> Dictionary:
	var side := randi_range(0, 3)
	var pos := Vector2.ZERO
	if side == 0:
		pos = Vector2(-30.0, randf() * WORLD_SIZE.y)
	elif side == 1:
		pos = Vector2(WORLD_SIZE.x + 30.0, randf() * WORLD_SIZE.y)
	elif side == 2:
		pos = Vector2(randf() * WORLD_SIZE.x, -30.0)
	else:
		pos = Vector2(randf() * WORLD_SIZE.x, WORLD_SIZE.y + 30.0)

	var elite: bool = randf() < min(0.22, max(0, wave - 4) * 0.018)
	if wave == MAX_ROUNDS:
		elite = elite or randf() < 0.22
	var bruiser: bool = (not elite) and randf() < min(0.28, wave * 0.035)
	var skitter: bool = (not bruiser) and randf() < 0.32
	var base_hp: float = 18.0 + wave * 5.2 + elapsed * 0.04
	var hp: float = base_hp
	var radius: float = 16.0
	var speed: float = 105.0 + wave * 4.0
	var damage: float = 12.0
	var color := Color("#b95b4b")
	var dropped_ore := 1
	var dropped_xp := 4

	if elite:
		hp = base_hp * 4.2
		radius = 29.0
		speed = 64.0 + wave * 2.6
		damage = 26.0
		color = Color("#6f4f86")
		dropped_ore = 9
		dropped_xp = 14
	elif bruiser:
		hp = base_hp * 2.4
		radius = 23.0
		speed = 72.0 + wave * 3.0
		damage = 20.0
		color = Color("#8d5746")
		dropped_ore = 4
		dropped_xp = 7
	elif skitter:
		hp = base_hp * 0.7
		radius = 12.0
		speed = 152.0 + wave * 5.0
		damage = 8.0
		color = Color("#93c96d")
		dropped_xp = 2

	var enemy_id := next_enemy_id
	next_enemy_id += 1

	return {
		"id": enemy_id,
		"pos": pos,
		"radius": radius,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"damage": damage,
		"color": color,
		"ore": dropped_ore,
		"xp": dropped_xp,
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
		var direction: Vector2 = (player["pos"] - enemy["pos"]).normalized()
		enemy["pos"] += direction * enemy["speed"] * delta

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
			_drop_pickups(enemy)
			_add_spark(enemy["pos"], enemy["color"], 14)
			enemies.remove_at(i)


func _hurt_enemy(enemy: Dictionary, damage: float, hit_pos: Vector2) -> void:
	enemy["hp"] -= damage
	_add_floating_text(str(int(round(damage))), hit_pos + Vector2(0, -8), Color("#f5efe3"))
	_add_spark(hit_pos, Color("#f5efe3"), 4)


func _drop_pickups(enemy: Dictionary) -> void:
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
	enemies.clear()
	bullets.clear()
	spawn_timer = 0.0
	screen_shake = 0.0

	if wave >= MAX_ROUNDS:
		_victory()
	else:
		_open_shop()


func _collect_leftover_ore() -> void:
	for item in pickups:
		if item["type"] == "ore":
			ore += item["value"]
			round_ore_earned += item["value"]
	pickups.clear()


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
	enemies.clear()
	bullets.clear()
	pickups.clear()
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
	var aim := (get_global_mouse_position() - pos).angle()
	draw_circle(pos, player["pickup_range"], Color(0.9, 0.72, 0.36, 0.08))
	draw_arc(pos, player["pickup_range"], 0.0, TAU, 96, Color(0.9, 0.72, 0.36, 0.16), 2.0)
	draw_set_transform(pos, aim, Vector2.ONE)
	var body_color := Color("#f5efe3") if player["hurt_cooldown"] > 0.0 else Color("#d4a44e")
	draw_rect(Rect2(Vector2(-18, -14), Vector2(34, 28)), body_color, true)
	draw_rect(Rect2(Vector2(2, -7), Vector2(25, 14)), Color("#2f332a"), true)
	draw_circle(Vector2(-8, -11), 5.0, Color("#f0643b"))
	draw_circle(Vector2(-8, 11), 5.0, Color("#f0643b"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_enemies() -> void:
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
		var radius: float = enemy["radius"]
		draw_circle(pos, radius, enemy["color"])
		draw_circle(pos + Vector2(-radius * 0.25, -radius * 0.2), radius * 0.35, Color(0, 0, 0, 0.28))
		var hp_ratio = clamp(enemy["hp"] / enemy["max_hp"], 0.0, 1.0)
		draw_rect(Rect2(pos + Vector2(-radius, -radius - 9), Vector2(radius * 2, 4)), Color("#111412"), true)
		draw_rect(Rect2(pos + Vector2(-radius, -radius - 9), Vector2(radius * 2 * hp_ratio, 4)), Color("#e6b85c"), true)


func _draw_bullets() -> void:
	for bullet in bullets:
		draw_circle(bullet["pos"], bullet["radius"], bullet["color"])


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
		"광맥 투기장",
		"20라운드를 버티며 광석을 모으고, 막간 상점에서 무기 6슬롯과 패시브 아이템을 완성하세요.",
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
		"20라운드 생존",
		"레벨 %d 광석 %d 무기 %d개 아이템 %d개로 기본 루프를 완주했습니다." % [level, ore, weapons.size(), items.size()],
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
