extends Node2D

const IDLE_PERIOD := 1.46
const MOVE_PERIOD := 0.72
const IDLE_TEXTURE_PATH := "res://assets/sprites/characters/miner_zombie_v1/zombie_idle.png"
const LEGACY_PROFILE := "legacy"

@export var auto_play := true
@export var texture_path := IDLE_TEXTURE_PATH
@export var motion_profile := LEGACY_PROFILE
@export var moving := false:
	set(value):
		moving = value
		if is_node_ready():
			_apply_current_pose()
@export var faces_right := false:
	set(value):
		faces_right = value
		if is_node_ready():
			_apply_facing_direction()

@onready var visual: Node2D = $Visual
@onready var shadow: Polygon2D = $Visual/Shadow
@onready var body: Sprite2D = $Visual/Body

var animation_time := 0.0
var _idle_texture: Texture2D
var _body_rest_position := Vector2.ZERO
var _body_rest_scale := Vector2.ONE
var _shadow_rest_scale := Vector2.ONE
var _shadow_rest_color := Color.BLACK


func _ready() -> void:
	_idle_texture = _load_png_texture(texture_path)
	body.texture = _idle_texture
	_store_rest_pose()
	_apply_facing_direction()
	_apply_current_pose()


func _process(delta: float) -> void:
	if not auto_play:
		return
	animation_time = fposmod(animation_time + delta, get_current_period())
	_apply_current_pose()


func get_current_period() -> float:
	if moving and motion_profile != LEGACY_PROFILE:
		return _motion_profile_period(motion_profile)
	return MOVE_PERIOD if moving else IDLE_PERIOD


func set_idle_time(value: float) -> void:
	animation_time = fposmod(value, get_current_period())
	if is_node_ready():
		_apply_current_pose()


func set_moving(enabled: bool) -> void:
	moving = enabled


func set_faces_right(enabled: bool) -> void:
	faces_right = enabled


func set_texture_path(path: String) -> void:
	texture_path = path
	if not is_node_ready():
		return
	_idle_texture = _load_png_texture(texture_path)
	body.texture = _idle_texture
	_apply_current_pose()


func set_motion_profile(profile: String) -> void:
	motion_profile = profile
	if is_node_ready():
		_apply_current_pose()


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Failed to load zombie rig texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _store_rest_pose() -> void:
	_body_rest_position = body.position
	_body_rest_scale = body.scale
	_shadow_rest_scale = shadow.scale
	_shadow_rest_color = shadow.color


func _apply_facing_direction() -> void:
	visual.scale.x = -1.0 if faces_right else 1.0


func _apply_current_pose() -> void:
	if moving:
		_apply_move_pose()
	else:
		_apply_idle_pose()


func _apply_idle_pose() -> void:
	var phase := animation_time / IDLE_PERIOD * TAU
	var breath := sin(phase)
	var lift := (1.0 - cos(phase)) * 0.5

	body.texture = _idle_texture
	body.position = _body_rest_position + Vector2(0.0, -2.0 * lift)
	body.rotation = deg_to_rad(1.2 * breath)
	body.scale = _body_rest_scale * Vector2(1.0 - 0.010 * lift, 1.0 + 0.012 * lift)

	shadow.scale = _shadow_rest_scale * Vector2(1.0 + 0.030 * lift, 1.0 + 0.010 * lift)
	shadow.color = Color(
		_shadow_rest_color.r,
		_shadow_rest_color.g,
		_shadow_rest_color.b,
		_shadow_rest_color.a - 0.025 * lift
	)


func _apply_move_pose() -> void:
	if motion_profile != LEGACY_PROFILE:
		_apply_profiled_move_pose()
		return

	var phase := animation_time / MOVE_PERIOD * TAU
	var step := sin(phase)
	var hop := absf(step)
	var drag := cos(phase)
	var lurch := sin(phase + PI * 0.22)

	body.texture = _idle_texture
	body.position = _body_rest_position + Vector2(6.5 * drag, -3.4 * hop + 1.2 * lurch)
	body.rotation = deg_to_rad(-5.2 * drag + 1.4 * lurch)
	body.scale = _body_rest_scale * Vector2(1.0 + 0.038 * hop, 1.0 - 0.044 * hop)

	shadow.scale = _shadow_rest_scale * Vector2(1.0 + 0.070 * hop, 1.0 + 0.025 * hop)
	shadow.color = Color(
		_shadow_rest_color.r,
		_shadow_rest_color.g,
		_shadow_rest_color.b,
		_shadow_rest_color.a - 0.045 * hop
	)


func _apply_profiled_move_pose() -> void:
	var phase := animation_time / _motion_profile_period(motion_profile) * TAU
	var pose := _motion_profile_pose(motion_profile, phase)

	body.texture = _idle_texture
	body.position = _body_rest_position + pose.local_pos
	body.rotation = pose.local_rot
	body.scale = _body_rest_scale * pose.local_scale

	shadow.scale = _shadow_rest_scale * Vector2(pose.shadow_scale_x, pose.shadow_scale_y)
	shadow.color = Color(
		_shadow_rest_color.r,
		_shadow_rest_color.g,
		_shadow_rest_color.b,
		float(pose.shadow_alpha)
	)


func _motion_profile_period(profile: String) -> float:
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


func _motion_profile_pose(profile: String, phase: float) -> Dictionary:
	var step := sin(phase)
	var drag := cos(phase)
	var lift := (1.0 - cos(phase)) * 0.5
	var double_step := sin(phase * 2.0)

	match profile:
		"sprint":
			var foot := absf(double_step)
			var push := maxf(0.0, drag)
			return {
				"local_pos": Vector2(2.4 + 1.8 * push - 0.7 * maxf(0.0, -drag), -1.15 * foot + 0.35 * double_step),
				"local_rot": deg_to_rad(-5.0 + 1.5 * step),
				"local_scale": Vector2(1.0 + 0.014 * foot, 1.0 - 0.013 * foot),
				"shadow_scale_x": 1.05 + 0.065 * push,
				"shadow_scale_y": 1.00 + 0.018 * push,
				"shadow_alpha": _shadow_rest_color.a + 0.035 * push
			}
		"brace":
			var press := (1.0 - cos(phase + PI * 0.16)) * 0.5
			return {
				"local_pos": Vector2(1.0 + 1.8 * press, -0.45 * press + 0.25 * double_step),
				"local_rot": deg_to_rad(-0.9 + 0.55 * step),
				"local_scale": Vector2(1.0 + 0.010 * press, 1.0 - 0.006 * press),
				"shadow_scale_x": 1.04 + 0.050 * press,
				"shadow_scale_y": 1.01 + 0.010 * press,
				"shadow_alpha": _shadow_rest_color.a + 0.030 * press
			}
		"heavy":
			var stomp := pow(lift, 2.0)
			return {
				"local_pos": Vector2(0.45 * step, 1.05 * stomp - 0.25 * (1.0 - lift)),
				"local_rot": deg_to_rad(0.65 * step),
				"local_scale": Vector2(1.0 + 0.018 * stomp, 1.0 - 0.016 * stomp),
				"shadow_scale_x": 1.03 + 0.080 * stomp,
				"shadow_scale_y": 1.00 + 0.024 * stomp,
				"shadow_alpha": _shadow_rest_color.a + 0.050 * stomp
			}
		"skitter":
			var skitter := absf(double_step)
			return {
				"local_pos": Vector2(1.15 * double_step + 0.35 * drag, -0.28 * skitter),
				"local_rot": deg_to_rad(0.85 * double_step),
				"local_scale": Vector2(1.0 + 0.006 * skitter, 1.0 - 0.005 * skitter),
				"shadow_scale_x": 1.04 + 0.025 * skitter,
				"shadow_scale_y": 1.00,
				"shadow_alpha": _shadow_rest_color.a + 0.020 * skitter
			}
		"throw":
			return {
				"local_pos": Vector2(1.15 * drag, -0.65 * lift + 0.35 * double_step),
				"local_rot": deg_to_rad(-1.25 * drag + 0.55 * double_step),
				"local_scale": Vector2(1.0 + 0.008 * lift, 1.0 - 0.007 * lift),
				"shadow_scale_x": 1.03 + 0.025 * lift,
				"shadow_scale_y": 1.00 + 0.010 * lift,
				"shadow_alpha": _shadow_rest_color.a + 0.020 * (1.0 - lift)
			}

	var limp := maxf(0.0, step)
	return {
		"local_pos": Vector2(2.2 * drag + 0.45 * double_step, -1.35 * limp + 0.35 * sin(phase + PI * 0.35)),
		"local_rot": deg_to_rad(-2.25 * drag + 0.45 * double_step),
		"local_scale": Vector2(1.0 + 0.014 * limp, 1.0 - 0.011 * limp),
		"shadow_scale_x": 1.02 + 0.030 * limp,
		"shadow_scale_y": 1.00 + 0.010 * limp,
		"shadow_alpha": _shadow_rest_color.a + 0.020 * limp
	}
