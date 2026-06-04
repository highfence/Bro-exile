extends Node

const ZombieRigScene := preload("res://scenes/animation/zombie_rig.tscn")

const DEFAULT_ASSET_NAME := "miner_zombie_single_image_runtime_v1"
const DEFAULT_OUTPUT_ROOT := "/private/tmp/bro-exile-zombie-harness"
const DEFAULT_SOURCE_FRAME := "res://assets/sprites/characters/miner_zombie_v1/zombie_idle.png"
const DEFAULT_MOTION_PROFILE := "legacy"
const DEFAULT_FRAME_COUNT := 24
const DEFAULT_CELL_SIZE := 256
const DEFAULT_PREVIEW_CELL_SIZE := 64
const SOURCE_VIEWPORT_SIZE := Vector2i(512, 512)
const SOURCE_RIG_POSITION := Vector2(256, 256)
const TARGET_OCCUPIED_SIZE := 224.0

const VARIANT_PRESETS := {
	"idle_left": {
		"moving": false,
		"faces_right": false,
		"fps": 10
	},
	"idle_right": {
		"moving": false,
		"faces_right": true,
		"fps": 10
	},
	"move_left": {
		"moving": true,
		"faces_right": false,
		"fps": 14
	},
	"move_right": {
		"moving": true,
		"faces_right": true,
		"fps": 14
	}
}

var _source_viewport: SubViewport
var _source_root: Node2D
var _zombie_rig
var _source_frames_by_variant := {}
var _source_loop_frames_by_variant := {}
var _legacy_frames_by_variant := {}
var _legacy_loop_frames_by_variant := {}
var _global_source_bbox := Rect2i()
var _cell_scale := 1.0
var _cell_offset := Vector2i.ZERO


func _ready() -> void:
	_run_harness.call_deferred()


func _run_harness() -> void:
	var config := _parse_config()
	var output_root := _globalize_output_path(config.output_root)
	var asset_dir := output_root.path_join(config.asset_name)
	DirAccess.make_dir_recursive_absolute(asset_dir)

	_setup_source_viewport(config.source_frame, config.motion_profile)

	if config.compare_legacy:
		_zombie_rig.set_texture_path(config.legacy_source_frame)
		_zombie_rig.set_motion_profile("legacy")
		for variant_name in config.variants:
			if not VARIANT_PRESETS.has(variant_name):
				push_error("Unknown zombie asset harness variant: %s" % variant_name)
				continue
			_legacy_frames_by_variant[variant_name] = await _capture_variant_source_frames(variant_name, config.frame_count)
			_legacy_loop_frames_by_variant[variant_name] = await _capture_variant_loop_frame(variant_name)

	_zombie_rig.set_texture_path(config.source_frame)
	_zombie_rig.set_motion_profile(config.motion_profile)

	for variant_name in config.variants:
		if not VARIANT_PRESETS.has(variant_name):
			push_error("Unknown zombie asset harness variant: %s" % variant_name)
			continue
		_source_frames_by_variant[variant_name] = await _capture_variant_source_frames(variant_name, config.frame_count)
		_source_loop_frames_by_variant[variant_name] = await _capture_variant_loop_frame(variant_name)

	_global_source_bbox = _calculate_global_bbox(config.variants)
	if _global_source_bbox.size == Vector2i.ZERO:
		push_error("Zombie asset harness captured empty frames.")
		get_tree().quit(1)
		return

	_calculate_cell_transform(config.cell_size)

	var metadata := {
		"asset_name": config.asset_name,
		"source_rig_scene": "res://scenes/animation/zombie_rig.tscn",
		"source_frame": config.source_frame,
		"motion_profile": config.motion_profile,
		"compare_legacy": config.compare_legacy,
		"legacy_source_frame": config.legacy_source_frame if config.compare_legacy else null,
		"output_dir": asset_dir,
		"cell_size": config.cell_size,
		"preview_cell_size": config.preview_cell_size,
		"frame_count": config.frame_count,
		"source_viewport_size": [SOURCE_VIEWPORT_SIZE.x, SOURCE_VIEWPORT_SIZE.y],
		"source_global_bbox": _rect_to_array(_global_source_bbox),
		"cell_scale": _cell_scale,
		"cell_offset": [_cell_offset.x, _cell_offset.y],
		"rig_contract": "single full-frame zombie sprite with engine-side scale, lean, bob, facing flip, and shadow pulse",
		"animations": [],
		"comparisons": [],
		"notes": [
			"Single-image enemy harness pass using a configurable source frame and motion profile.",
			"This follows the lightweight enemy asset direction: one readable enemy image plus runtime motion effects.",
			"Optional comparison previews stack legacy motion above the requested profile.",
			"Feedback should focus on silhouette, wobble amount, facing, and move rhythm."
		]
	}

	for variant_name in config.variants:
		if not _source_frames_by_variant.has(variant_name):
			continue
		metadata.animations.append(_write_variant_outputs(
			asset_dir,
			variant_name,
			config.frame_count,
			config.cell_size,
			config.preview_cell_size
		))

	if config.compare_legacy:
		metadata.comparisons = _write_comparison_outputs(
			asset_dir,
			config.variants,
			config.frame_count,
			config.cell_size,
			config.preview_cell_size,
			config.motion_profile
		)

	_write_json(asset_dir.path_join("metadata.json"), metadata)
	print("ZOMBIE_ASSET_HARNESS_DONE path=%s variants=%s" % [asset_dir, config.variants])
	get_tree().quit()


func _parse_config() -> Dictionary:
	var config := {
		"asset_name": DEFAULT_ASSET_NAME,
		"output_root": DEFAULT_OUTPUT_ROOT,
		"source_frame": DEFAULT_SOURCE_FRAME,
		"legacy_source_frame": DEFAULT_SOURCE_FRAME,
		"motion_profile": DEFAULT_MOTION_PROFILE,
		"compare_legacy": false,
		"frame_count": DEFAULT_FRAME_COUNT,
		"cell_size": DEFAULT_CELL_SIZE,
		"preview_cell_size": DEFAULT_PREVIEW_CELL_SIZE,
		"variants": ["idle_left", "idle_right", "move_left", "move_right"]
	}

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--asset-name="):
			config.asset_name = arg.trim_prefix("--asset-name=")
		elif arg.begins_with("--asset-output="):
			config.output_root = arg.trim_prefix("--asset-output=")
		elif arg.begins_with("--source-frame="):
			config.source_frame = arg.trim_prefix("--source-frame=")
		elif arg.begins_with("--legacy-source-frame="):
			config.legacy_source_frame = arg.trim_prefix("--legacy-source-frame=")
		elif arg.begins_with("--motion-profile="):
			config.motion_profile = arg.trim_prefix("--motion-profile=")
		elif arg == "--compare-legacy":
			config.compare_legacy = true
		elif arg.begins_with("--frame-count="):
			config.frame_count = int(arg.trim_prefix("--frame-count="))
		elif arg.begins_with("--cell-size="):
			config.cell_size = int(arg.trim_prefix("--cell-size="))
		elif arg.begins_with("--preview-cell-size="):
			config.preview_cell_size = int(arg.trim_prefix("--preview-cell-size="))
		elif arg.begins_with("--animations="):
			config.variants = Array(arg.trim_prefix("--animations=").split(",", false))

	config.frame_count = maxi(2, config.frame_count)
	config.cell_size = maxi(32, config.cell_size)
	config.preview_cell_size = maxi(16, config.preview_cell_size)
	if str(config.legacy_source_frame).is_empty():
		config.legacy_source_frame = config.source_frame
	return config


func _globalize_output_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path


func _setup_source_viewport(source_frame: String, motion_profile: String) -> void:
	_source_viewport = SubViewport.new()
	_source_viewport.size = SOURCE_VIEWPORT_SIZE
	_source_viewport.transparent_bg = true
	_source_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_source_viewport)

	_source_root = Node2D.new()
	_source_viewport.add_child(_source_root)

	_zombie_rig = ZombieRigScene.instantiate()
	_zombie_rig.name = "HarnessZombieRig"
	_zombie_rig.auto_play = false
	_zombie_rig.texture_path = source_frame
	_zombie_rig.motion_profile = motion_profile
	_zombie_rig.position = SOURCE_RIG_POSITION
	_source_root.add_child(_zombie_rig)


func _capture_variant_source_frames(variant_name: String, frame_count: int) -> Array:
	var preset: Dictionary = VARIANT_PRESETS[variant_name]
	_zombie_rig.set_faces_right(preset.faces_right)
	_zombie_rig.set_moving(preset.moving)

	var period: float = _zombie_rig.get_current_period()
	var frames := []
	for frame_index in range(frame_count):
		var frame_time := period * float(frame_index) / float(frame_count)
		_zombie_rig.set_idle_time(frame_time)
		frames.append(await _capture_source_viewport_image())
	return frames


func _capture_variant_loop_frame(variant_name: String) -> Image:
	var preset: Dictionary = VARIANT_PRESETS[variant_name]
	_zombie_rig.set_faces_right(preset.faces_right)
	_zombie_rig.set_moving(preset.moving)
	_zombie_rig.set_idle_time(_zombie_rig.get_current_period())
	return await _capture_source_viewport_image()


func _capture_source_viewport_image() -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := _source_viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


func _calculate_global_bbox(variant_names: Array) -> Rect2i:
	var has_pixels := false
	var min_x := SOURCE_VIEWPORT_SIZE.x
	var min_y := SOURCE_VIEWPORT_SIZE.y
	var max_x := 0
	var max_y := 0

	var frame_sets := [_source_frames_by_variant]
	if not _legacy_frames_by_variant.is_empty():
		frame_sets.append(_legacy_frames_by_variant)

	for frames_by_variant in frame_sets:
		for variant_name in variant_names:
			if not frames_by_variant.has(variant_name):
				continue
			for image in frames_by_variant[variant_name]:
				var bbox := _calculate_alpha_bbox(image)
				if bbox.size == Vector2i.ZERO:
					continue
				has_pixels = true
				min_x = mini(min_x, bbox.position.x)
				min_y = mini(min_y, bbox.position.y)
				max_x = maxi(max_x, bbox.position.x + bbox.size.x)
				max_y = maxi(max_y, bbox.position.y + bbox.size.y)

	if not has_pixels:
		return Rect2i()

	var padded_min := Vector2i(maxi(0, min_x - 4), maxi(0, min_y - 4))
	var padded_max := Vector2i(
		mini(SOURCE_VIEWPORT_SIZE.x, max_x + 4),
		mini(SOURCE_VIEWPORT_SIZE.y, max_y + 4)
	)
	return Rect2i(padded_min, padded_max - padded_min)


func _calculate_alpha_bbox(image: Image) -> Rect2i:
	var width := image.get_width()
	var height := image.get_height()
	var has_pixels := false
	var min_x := width
	var min_y := height
	var max_x := 0
	var max_y := 0

	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			has_pixels = true
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x + 1)
			max_y = maxi(max_y, y + 1)

	if not has_pixels:
		return Rect2i()
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x, max_y - min_y))


func _calculate_cell_transform(cell_size: int) -> void:
	var largest_axis := float(maxi(_global_source_bbox.size.x, _global_source_bbox.size.y))
	_cell_scale = minf(1.0, TARGET_OCCUPIED_SIZE / largest_axis)
	var packed_size := Vector2i(
		int(round(float(_global_source_bbox.size.x) * _cell_scale)),
		int(round(float(_global_source_bbox.size.y) * _cell_scale))
	)
	_cell_offset = Vector2i(
		int(round(float(cell_size - packed_size.x) * 0.5)),
		int(round(float(cell_size - packed_size.y) * 0.5))
	)


func _write_variant_outputs(
	asset_dir: String,
	variant_name: String,
	frame_count: int,
	cell_size: int,
	preview_cell_size: int
) -> Dictionary:
	var variant_dir := asset_dir.path_join(variant_name)
	var frames_dir := variant_dir.path_join("frames")
	DirAccess.make_dir_recursive_absolute(frames_dir)

	var cell_frames := []
	for frame_index in range(frame_count):
		var cell := _pack_source_frame_to_cell(_source_frames_by_variant[variant_name][frame_index], cell_size)
		cell_frames.append(cell)
		cell.save_png(frames_dir.path_join("%s_%02d.png" % [variant_name, frame_index]))

	var sheet := _make_horizontal_sheet(cell_frames, cell_size)
	var sheet_name := "%s_sheet_%dx1_%d.png" % [variant_name, frame_count, cell_size]
	sheet.save_png(variant_dir.path_join(sheet_name))

	var preview := sheet.duplicate()
	preview.resize(frame_count * preview_cell_size, preview_cell_size, Image.INTERPOLATE_LANCZOS)
	var preview_name := "%s_sheet_%dx1_%d_preview.png" % [variant_name, frame_count, preview_cell_size]
	preview.save_png(variant_dir.path_join(preview_name))

	var loop_cell := _pack_source_frame_to_cell(_source_loop_frames_by_variant[variant_name], cell_size)
	var loop_verification := _compare_images(cell_frames[0], loop_cell)
	var adjacent_duplicates := _count_adjacent_duplicate_pairs(cell_frames)

	var preset: Dictionary = VARIANT_PRESETS[variant_name]
	_zombie_rig.set_moving(preset.moving)
	var metadata := {
		"name": variant_name,
		"moving": preset.moving,
		"faces_right": preset.faces_right,
		"fps": preset.fps,
		"motion_profile": _zombie_rig.motion_profile,
		"period": _zombie_rig.get_current_period(),
		"frame_count": frame_count,
		"frames_dir": "%s/frames" % variant_name,
		"sheet": "%s/%s" % [variant_name, sheet_name],
		"preview_64": "%s/%s" % [variant_name, preview_name],
		"verification": {
			"loop_matches_first_frame": loop_verification.mean_abs_diff_rgba <= 0.001 and loop_verification.alpha_mismatch_pixels == 0,
			"loop_mean_abs_diff_rgba": loop_verification.mean_abs_diff_rgba,
			"loop_alpha_mismatch_pixels": loop_verification.alpha_mismatch_pixels,
			"adjacent_duplicate_pairs": adjacent_duplicates
		}
	}
	_write_json(variant_dir.path_join("metadata.json"), metadata)
	return metadata


func _write_comparison_outputs(
	asset_dir: String,
	variant_names: Array,
	frame_count: int,
	cell_size: int,
	preview_cell_size: int,
	motion_profile: String
) -> Array:
	var comparison_dir := asset_dir.path_join("comparison")
	DirAccess.make_dir_recursive_absolute(comparison_dir)
	var comparisons := []

	for variant_name in variant_names:
		if not _legacy_frames_by_variant.has(variant_name) or not _source_frames_by_variant.has(variant_name):
			continue

		var legacy_cells := []
		var profile_cells := []
		for frame_index in range(frame_count):
			legacy_cells.append(_pack_source_frame_to_cell(_legacy_frames_by_variant[variant_name][frame_index], cell_size))
			profile_cells.append(_pack_source_frame_to_cell(_source_frames_by_variant[variant_name][frame_index], cell_size))

		var legacy_preview := _make_horizontal_sheet(legacy_cells, cell_size)
		legacy_preview.resize(frame_count * preview_cell_size, preview_cell_size, Image.INTERPOLATE_LANCZOS)

		var profile_preview := _make_horizontal_sheet(profile_cells, cell_size)
		profile_preview.resize(frame_count * preview_cell_size, preview_cell_size, Image.INTERPOLATE_LANCZOS)

		var comparison := Image.create(frame_count * preview_cell_size, preview_cell_size * 2, false, Image.FORMAT_RGBA8)
		comparison.fill(Color(0, 0, 0, 0))
		comparison.blit_rect(legacy_preview, Rect2i(Vector2i.ZERO, legacy_preview.get_size()), Vector2i.ZERO)
		comparison.blit_rect(profile_preview, Rect2i(Vector2i.ZERO, profile_preview.get_size()), Vector2i(0, preview_cell_size))

		var file_name := "%s_legacy_vs_%s_%d_preview.png" % [variant_name, motion_profile, preview_cell_size]
		comparison.save_png(comparison_dir.path_join(file_name))
		comparisons.append({
			"name": variant_name,
			"legacy_motion_profile": "legacy",
			"new_motion_profile": motion_profile,
			"preview_64": "comparison/%s" % file_name,
			"layout": "top row legacy, bottom row new profile"
		})

	return comparisons


func _pack_source_frame_to_cell(source_image: Image, cell_size: int) -> Image:
	var crop := Image.create(_global_source_bbox.size.x, _global_source_bbox.size.y, false, Image.FORMAT_RGBA8)
	crop.fill(Color(0, 0, 0, 0))
	crop.blit_rect(source_image, _global_source_bbox, Vector2i.ZERO)

	if not is_equal_approx(_cell_scale, 1.0):
		crop.resize(
			maxi(1, int(round(float(crop.get_width()) * _cell_scale))),
			maxi(1, int(round(float(crop.get_height()) * _cell_scale))),
			Image.INTERPOLATE_LANCZOS
		)

	var cell := Image.create(cell_size, cell_size, false, Image.FORMAT_RGBA8)
	cell.fill(Color(0, 0, 0, 0))
	cell.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), _cell_offset)
	return cell


func _make_horizontal_sheet(frames: Array, cell_size: int) -> Image:
	var sheet := Image.create(cell_size * frames.size(), cell_size, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for frame_index in range(frames.size()):
		sheet.blit_rect(
			frames[frame_index],
			Rect2i(Vector2i.ZERO, Vector2i(cell_size, cell_size)),
			Vector2i(cell_size * frame_index, 0)
		)
	return sheet


func _compare_images(left_image: Image, right_image: Image) -> Dictionary:
	var width := mini(left_image.get_width(), right_image.get_width())
	var height := mini(left_image.get_height(), right_image.get_height())
	var total_diff := 0.0
	var alpha_mismatch_pixels := 0

	for y in range(height):
		for x in range(width):
			var left_color := left_image.get_pixel(x, y)
			var right_color := right_image.get_pixel(x, y)
			total_diff += absf(left_color.r - right_color.r)
			total_diff += absf(left_color.g - right_color.g)
			total_diff += absf(left_color.b - right_color.b)
			total_diff += absf(left_color.a - right_color.a)
			if absf(left_color.a - right_color.a) > 0.01:
				alpha_mismatch_pixels += 1

	return {
		"mean_abs_diff_rgba": total_diff / float(width * height * 4),
		"alpha_mismatch_pixels": alpha_mismatch_pixels
	}


func _count_adjacent_duplicate_pairs(frames: Array) -> int:
	var duplicates := 0
	for frame_index in range(frames.size()):
		var next_index := (frame_index + 1) % frames.size()
		var diff := _compare_images(frames[frame_index], frames[next_index])
		if diff.mean_abs_diff_rgba <= 0.001 and diff.alpha_mismatch_pixels == 0:
			duplicates += 1
	return duplicates


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write JSON: %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.store_string("\n")


func _rect_to_array(rect: Rect2i) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
