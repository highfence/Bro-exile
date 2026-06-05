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
var _shadow_rest_position := Vector2.ZERO
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
	_shadow_rest_position = shadow.position
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

	shadow.position = _shadow_rest_position
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

	shadow.position = _shadow_rest_position
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

	shadow.position = _shadow_rest_position + Vector2(0.0, float(pose.get("shadow_y_offset", 0.0)))
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
