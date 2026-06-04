extends Node2D

const IDLE_PERIOD := 1.46
const MOVE_PERIOD := 0.72
const IDLE_TEXTURE_PATH := "res://assets/sprites/characters/miner_zombie_v1/zombie_idle.png"

@export var auto_play := true
@export var texture_path := IDLE_TEXTURE_PATH
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
