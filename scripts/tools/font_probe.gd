extends SceneTree

const OreUITheme = preload("res://scripts/ui/ore_ui_theme.gd")


func _init() -> void:
	var font_path := OreUITheme.FONT_PATH
	var file_exists: bool = FileAccess.file_exists(font_path)
	var font_resource: Resource = null
	var has_text_server: bool = OreUITheme.ensure_text_rendering_available()
	var font_loads: bool = false
	var has_metrics: bool = false

	print("FONT_PROBE file_exists=", file_exists)
	print("FONT_PROBE primary=", TextServerManager.get_primary_interface())
	for i in range(TextServerManager.get_interface_count()):
		var server := TextServerManager.get_interface(i)
		print("FONT_PROBE text_server_", i, "=", server)

	var resource_exists: bool = ResourceLoader.exists(font_path)
	print("FONT_PROBE resource_exists=", resource_exists)
	if resource_exists:
		font_resource = load(font_path)
	if not (font_resource is Font):
		font_resource = OreUITheme.load_font()
	print("FONT_PROBE resource=", font_resource)
	print("FONT_PROBE is_font=", font_resource is Font)

	if font_resource is Font:
		var font: Font = font_resource as Font
		var height: float = font.get_height(24)
		var size: Vector2 = font.get_string_size("광맥 투기장 ABC 123", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24)
		print("FONT_PROBE height=", height)
		print("FONT_PROBE size=", size)
		font_loads = true
		has_metrics = height > 0.0 and size.x > 0.0 and size.y > 0.0

	var ok: bool = file_exists and has_text_server and font_loads and has_metrics
	print("FONT_PROBE ok=", ok)
	quit(0 if ok else 1)
