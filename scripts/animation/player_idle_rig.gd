extends Node2D

const IDLE_PERIOD := 1.32
const CORE_BODY_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/core_body.png"
const LEFT_GLOVE_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/left_glove.png"
const RIGHT_GLOVE_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/right_glove.png"
const LEFT_BOOT_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/left_boot.png"
const RIGHT_BOOT_PATH := "res://assets/sprites/characters/player_helmet_mascot_semilayered_gloves_v1/parts/right_boot.png"

@export var auto_play := true

@onready var shadow: Polygon2D = $Shadow
@onready var body: Node2D = $Body
@onready var gloves: Node2D = $Gloves
@onready var boots: Node2D = $Boots
@onready var core_body: Sprite2D = $Body/CoreBody
@onready var left_glove: Sprite2D = $Gloves/LeftGlove
@onready var right_glove: Sprite2D = $Gloves/RightGlove
@onready var left_boot: Sprite2D = $Boots/LeftBoot
@onready var right_boot: Sprite2D = $Boots/RightBoot

var idle_time := 0.0

var _body_rest_position := Vector2.ZERO
var _body_rest_scale := Vector2.ONE
var _gloves_rest_position := Vector2.ZERO
var _boots_rest_position := Vector2.ZERO
var _left_glove_rest_position := Vector2.ZERO
var _right_glove_rest_position := Vector2.ZERO
var _left_boot_rest_position := Vector2.ZERO
var _right_boot_rest_position := Vector2.ZERO
var _shadow_rest_scale := Vector2.ONE
var _shadow_rest_color := Color.BLACK


func _ready() -> void:
	_load_part_textures()
	_store_rest_pose()
	set_idle_time(idle_time)


func _process(delta: float) -> void:
	if not auto_play:
		return
	idle_time = fposmod(idle_time + delta, IDLE_PERIOD)
	_apply_idle_pose()


func get_idle_period() -> float:
	return IDLE_PERIOD


func set_idle_time(value: float) -> void:
	idle_time = fposmod(value, IDLE_PERIOD)
	if is_node_ready():
		_apply_idle_pose()


func _load_part_textures() -> void:
	core_body.texture = _load_png_texture(CORE_BODY_PATH)
	left_glove.texture = _load_png_texture(LEFT_GLOVE_PATH)
	right_glove.texture = _load_png_texture(RIGHT_GLOVE_PATH)
	left_boot.texture = _load_png_texture(LEFT_BOOT_PATH)
	right_boot.texture = _load_png_texture(RIGHT_BOOT_PATH)


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Failed to load player idle part: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _store_rest_pose() -> void:
	_body_rest_position = body.position
	_body_rest_scale = body.scale
	_gloves_rest_position = gloves.position
	_boots_rest_position = boots.position
	_left_glove_rest_position = left_glove.position
	_right_glove_rest_position = right_glove.position
	_left_boot_rest_position = left_boot.position
	_right_boot_rest_position = right_boot.position
	_shadow_rest_scale = shadow.scale
	_shadow_rest_color = shadow.color


func _apply_idle_pose() -> void:
	var phase := idle_time / IDLE_PERIOD * TAU
	var breath := sin(phase)
	var lift := (1.0 - cos(phase)) * 0.5
	var settle := sin(phase * 2.0)

	# Brotato reference assets are mostly static, same-canvas parts; the life comes
	# from engine-side transform animation rather than drawing a full frame sheet.
	body.position = _body_rest_position + Vector2(0.0, -4.5 * lift + 0.9 * settle)
	body.rotation = deg_to_rad(1.1 * breath)
	body.scale = _body_rest_scale * Vector2(1.0 - 0.010 * lift, 1.0 + 0.014 * lift)

	gloves.position = _gloves_rest_position + Vector2(0.0, -2.5 * lift)
	left_glove.position = _left_glove_rest_position + Vector2(-1.8 * breath, 1.2 * settle)
	right_glove.position = _right_glove_rest_position + Vector2(-1.4 * breath, -1.0 * settle)
	left_glove.rotation = deg_to_rad(-2.5 + 5.0 * sin(phase + PI * 0.18))
	right_glove.rotation = deg_to_rad(2.5 + 5.0 * sin(phase + PI * 0.82))

	boots.position = _boots_rest_position + Vector2(0.0, 1.0 * lift)
	left_boot.position = _left_boot_rest_position + Vector2(-0.7 * breath, 0.5 * settle)
	right_boot.position = _right_boot_rest_position + Vector2(-0.5 * breath, -0.45 * settle)
	left_boot.rotation = deg_to_rad(-1.0 + 1.7 * sin(phase + PI * 0.35))
	right_boot.rotation = deg_to_rad(1.0 + 1.7 * sin(phase + PI * 0.65))

	shadow.scale = _shadow_rest_scale * Vector2(1.0 + 0.035 * lift, 1.0 + 0.012 * lift)
	shadow.color = Color(
		_shadow_rest_color.r,
		_shadow_rest_color.g,
		_shadow_rest_color.b,
		_shadow_rest_color.a - 0.035 * lift
	)
