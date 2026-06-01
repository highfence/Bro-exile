extends Node2D

const PlayerIdleRigScene := preload("res://scenes/animation/player_idle_rig.tscn")
const CAPTURE_DIR := "/private/tmp/bro-exile-player-idle"
const CAPTURE_FRAME_COUNT := 24
const WORLD_SIZE := Vector2(1280, 720)

var player_rig


func _ready() -> void:
	var user_args := OS.get_cmdline_user_args()
	var all_args := OS.get_cmdline_args()
	print("PLAYER_IDLE_TEST_READY user_args=%s all_args=%s" % [user_args, all_args])

	player_rig = PlayerIdleRigScene.instantiate()
	player_rig.name = "SpawnedPlayerIdleRig"
	player_rig.position = Vector2(640, 395)
	player_rig.scale = Vector2(1.28, 1.28)
	add_child(player_rig)

	if user_args.has("--capture-player-idle") or all_args.has("--capture-player-idle"):
		player_rig.auto_play = false
		_capture_idle_loop_and_quit.call_deferred()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#141711"), true)
	for x in range(-120, int(WORLD_SIZE.x) + 120, 80):
		draw_line(Vector2(x, 0), Vector2(x - 160, WORLD_SIZE.y), Color(1, 0.96, 0.82, 0.045), 1.0)
	for x in range(0, int(WORLD_SIZE.x), 64):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color(0.68, 0.62, 0.50, 0.035), 1.0)
	for y in range(0, int(WORLD_SIZE.y), 64):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color(0.68, 0.62, 0.50, 0.035), 1.0)
	draw_circle(Vector2(640, 390), 250.0, Color(0.95, 0.78, 0.40, 0.05))
	draw_arc(Vector2(640, 390), 250.0, 0.0, TAU, 96, Color(0.95, 0.78, 0.40, 0.10), 2.0)


func _capture_idle_loop_and_quit() -> void:
	DirAccess.make_dir_recursive_absolute(CAPTURE_DIR)
	await get_tree().process_frame

	var period: float = player_rig.get_idle_period()
	for frame in range(CAPTURE_FRAME_COUNT + 1):
		var time := period * float(frame) / float(CAPTURE_FRAME_COUNT)
		player_rig.set_idle_time(time)
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/idle_%02d.png" % [CAPTURE_DIR, frame])

	print("PLAYER_IDLE_CAPTURE frames=%d period=%.2f path=%s" % [CAPTURE_FRAME_COUNT + 1, period, CAPTURE_DIR])
	get_tree().quit()
