extends CanvasLayer

class_name GameUI

signal start_requested
signal option_selected(option: Dictionary)

const OreUITheme = preload("res://scripts/ui/ore_ui_theme.gd")

var root: Control
var brand_title: Label
var brand_subtitle: Label
var hp_bar: ProgressBar
var hp_value: Label
var xp_bar: ProgressBar
var xp_value: Label
var wave_label: Label
var ore_label: Label
var time_label: Label
var weapon_box: HBoxContainer
var overlay: Control
var overlay_panel: PanelContainer
var overlay_box: VBoxContainer
var pause_banner: Control


func setup(font: Font) -> void:
	layer = 10
	root = Control.new()
	root.name = "GameUIRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = OreUITheme.create_theme(font)
	add_child(root)

	_build_hud()
	_build_overlay()
	_build_pause_banner()


func update_hud(data: Dictionary) -> void:
	if hp_bar == null:
		return

	var max_hp: float = float(data.get("max_hp", 100.0))
	var hp: float = clampf(float(data.get("hp", 0.0)), 0.0, max_hp)
	var xp_max: float = float(data.get("xp_to_next", 1.0))
	var current_xp: float = clampf(float(data.get("xp", 0.0)), 0.0, xp_max)

	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_value.text = "%d / %d" % [int(round(hp)), int(round(max_hp))]
	xp_bar.max_value = xp_max
	xp_bar.value = current_xp
	xp_value.text = "Lv.%d  %d / %d" % [int(data.get("level", 1)), int(round(current_xp)), int(round(xp_max))]
	wave_label.text = "공세 %d" % int(data.get("wave", 1))
	ore_label.text = "광석 %d" % int(data.get("ore", 0))
	time_label.text = str(data.get("time", "00:00"))


func render_weapons(weapons: Array, damage_multiplier: float) -> void:
	_clear_children(weapon_box)
	if weapons.is_empty():
		var empty := _make_label("무기 없음", 13, OreUITheme.MUTED)
		weapon_box.add_child(empty)
		return

	for weapon in weapons:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(138, 42)
		card.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.12, 0.13, 0.11, 0.88), OreUITheme.LINE, 8, 1))
		weapon_box.add_child(card)

		var margin := _margin(10, 8, 10, 7)
		card.add_child(margin)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		margin.add_child(box)

		var title := _make_label(str(weapon["name"]), 12, OreUITheme.INK)
		title.clip_text = true
		var detail := _make_label("%d단계  피해 %d" % [int(weapon["level"]), int(round(float(weapon["damage"]) * damage_multiplier))], 11, OreUITheme.MUTED)
		detail.clip_text = true
		box.add_child(title)
		box.add_child(detail)


func show_start(eyebrow: String, title: String, body: String, button_text: String) -> void:
	_prepare_overlay(Vector2(650, 0), OreUITheme.PANEL_STRONG)
	overlay_box.add_child(_make_label(eyebrow, 14, OreUITheme.ORE))
	overlay_box.add_child(_make_label(title, 46, OreUITheme.INK))

	var body_label := _make_label(body, 16, OreUITheme.MUTED)
	body_label.custom_minimum_size = Vector2(560, 58)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_box.add_child(body_label)

	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(240, 46)
	button.pressed.connect(func(): start_requested.emit())
	overlay_box.add_child(button)
	overlay.visible = true


func show_choice(eyebrow: String, title: String, options: Array) -> void:
	var tall := options.size() > 3
	var columns: int = 2 if tall else 3
	var card_height: int = 132 if tall else 120
	_prepare_overlay(Vector2(900, 0), OreUITheme.PANEL_STRONG)
	overlay_box.add_child(_make_label(eyebrow, 14, OreUITheme.ORE))
	overlay_box.add_child(_make_label(title, 34, OreUITheme.INK))

	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(grid)

	for option in options:
		grid.add_child(_make_option_card(option, card_height))

	overlay.visible = true


func show_end(eyebrow: String, title: String, body: String, button_text: String) -> void:
	_prepare_overlay(Vector2(660, 0), OreUITheme.PANEL_STRONG)
	overlay_box.add_child(_make_label(eyebrow, 14, OreUITheme.ORE))
	overlay_box.add_child(_make_label(title, 40, OreUITheme.INK))

	var body_label := _make_label(body, 16, OreUITheme.MUTED)
	body_label.custom_minimum_size = Vector2(560, 80)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_box.add_child(body_label)

	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(240, 46)
	button.pressed.connect(func(): start_requested.emit())
	overlay_box.add_child(button)
	overlay.visible = true


func hide_overlay() -> void:
	overlay.visible = false


func set_paused(value: bool) -> void:
	pause_banner.visible = value


func _build_hud() -> void:
	var top_panel := PanelContainer.new()
	top_panel.name = "TopHud"
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 12
	top_panel.offset_top = 12
	top_panel.offset_right = -12
	top_panel.offset_bottom = 70
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(OreUITheme.PANEL, OreUITheme.LINE, 8, 1))
	root.add_child(top_panel)

	var top_margin := _margin(12, 8, 12, 8)
	top_panel.add_child(top_margin)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top_margin.add_child(top)

	var brand := _brand_block()
	top.add_child(brand)

	var hp_meter := _meter_block("체력", OreUITheme.EMBER)
	hp_bar = hp_meter["bar"]
	hp_value = hp_meter["value"]
	top.add_child(hp_meter["node"])

	var xp_meter := _meter_block("경험", OreUITheme.AQUA)
	xp_bar = xp_meter["bar"]
	xp_value = xp_meter["value"]
	top.add_child(xp_meter["node"])

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 1)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(stats)

	wave_label = _stat_pill("공세 1", OreUITheme.INK)
	ore_label = _stat_pill("광석 0", OreUITheme.ORE)
	time_label = _stat_pill("00:00", OreUITheme.MUTED)
	stats.add_child(wave_label)
	stats.add_child(ore_label)
	stats.add_child(time_label)

	var weapon_panel := PanelContainer.new()
	weapon_panel.name = "WeaponHud"
	weapon_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	weapon_panel.offset_left = 12
	weapon_panel.offset_top = -66
	weapon_panel.offset_right = 960
	weapon_panel.offset_bottom = -12
	weapon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.10, 0.11, 0.09, 0.84), OreUITheme.LINE, 8, 1))
	root.add_child(weapon_panel)

	var weapon_margin := _margin(10, 7, 10, 7)
	weapon_panel.add_child(weapon_margin)
	weapon_box = HBoxContainer.new()
	weapon_box.add_theme_constant_override("separation", 8)
	weapon_margin.add_child(weapon_box)


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = OreUITheme.SHADE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	overlay_panel = PanelContainer.new()
	overlay_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(OreUITheme.PANEL_STRONG, OreUITheme.LINE_STRONG, 8, 1))
	center.add_child(overlay_panel)

	var panel_margin := _margin(28, 24, 28, 24)
	overlay_panel.add_child(panel_margin)

	overlay_box = VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation", 12)
	overlay_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_margin.add_child(overlay_box)


func _build_pause_banner() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.visible = false
	root.add_child(center)
	pause_banner = center

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 92)
	panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.06, 0.065, 0.055, 0.92), OreUITheme.LINE_STRONG, 8, 1))
	center.add_child(panel)

	var margin := _margin(18, 14, 18, 14)
	panel.add_child(margin)

	var label := _make_label("일시 정지", 30, OreUITheme.INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(label)


func _prepare_overlay(size: Vector2, color: Color) -> void:
	_clear_children(overlay_box)
	overlay_panel.custom_minimum_size = size
	overlay_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(color, OreUITheme.LINE_STRONG, 8, 1))


func _make_option_card(option: Dictionary, min_height: int) -> Control:
	var disabled := bool(option.get("disabled", false))
	var card := Control.new()
	card.custom_minimum_size = Vector2(0, min_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("normal", disabled))
	card.add_child(panel)

	var margin := _margin(14, 12, 14, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var title_color := OreUITheme.DIM if disabled else OreUITheme.INK
	var desc_color := Color(0.58, 0.55, 0.49, 0.72) if disabled else OreUITheme.MUTED
	var meta_color := Color(0.72, 0.66, 0.52, 0.56) if disabled else OreUITheme.ORE

	var title := _make_label(str(option.get("name", "")), 18 if min_height > 120 else 15, title_color)
	title.clip_text = true
	title.custom_minimum_size = Vector2(0, 26 if min_height > 120 else 22)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(title)

	var desc := _make_label(str(option.get("desc", "")), 13, desc_color)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 48 if min_height > 120 else 32)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	box.add_child(desc)

	var meta := _make_label(str(option.get("meta_text", "")), 12, meta_color)
	meta.clip_text = true
	meta.custom_minimum_size = Vector2(0, 20)
	meta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(meta)

	if not disabled:
		var hit_area := Button.new()
		hit_area.text = ""
		hit_area.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		hit_area.focus_mode = Control.FOCUS_ALL
		for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			hit_area.add_theme_stylebox_override(style_name, OreUITheme.transparent_style())
		hit_area.mouse_entered.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("hover")))
		hit_area.mouse_exited.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("normal")))
		hit_area.button_down.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("pressed")))
		hit_area.button_up.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("hover")))
		hit_area.pressed.connect(func(): option_selected.emit(option))
		card.add_child(hit_area)
	return card


func _brand_block() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(194, 42)
	panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(OreUITheme.PANEL_SOFT, OreUITheme.LINE, 8, 1))

	var margin := _margin(12, 7, 12, 7)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	brand_title = _make_label("광맥 투기장", 15, OreUITheme.INK)
	brand_subtitle = _make_label("봉인된 채굴지", 11, OreUITheme.MUTED)
	box.add_child(brand_title)
	box.add_child(brand_subtitle)
	return panel


func _meter_block(title: String, color: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(210, 42)
	panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(OreUITheme.PANEL_SOFT, OreUITheme.LINE, 8, 1))

	var margin := _margin(10, 7, 10, 7)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	row.add_child(_make_label(title, 11, OreUITheme.MUTED))

	var value := _make_label("", 11, OreUITheme.INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 9)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", OreUITheme.meter_background())
	bar.add_theme_stylebox_override("fill", OreUITheme.meter_fill(color))
	box.add_child(bar)

	return {"node": panel, "bar": bar, "value": value}


func _stat_pill(text: String, color: Color) -> Label:
	var label := _make_label(text, 15, color)
	label.custom_minimum_size = Vector2(102, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
