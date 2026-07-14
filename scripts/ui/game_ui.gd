extends CanvasLayer

class_name GameUI

signal start_requested
signal option_selected(option: Dictionary)
signal resume_requested
signal restart_requested

const OreUITheme = preload("res://scripts/ui/ore_ui_theme.gd")

var root: Control
var brand_title: Label
var brand_subtitle: Label
var hp_bar: ProgressBar
var hp_value: Label
var xp_bar: ProgressBar
var xp_value: Label
var wave_label: Label
var wallet_labels := {}
var time_label: Label
var top_panel: PanelContainer
var weapon_panel: PanelContainer
var weapon_box: HBoxContainer
var relic_panel: PanelContainer
var relic_box: HBoxContainer
var risk_panel: PanelContainer
var risk_label: Label
var overlay: Control
var overlay_panel: PanelContainer
var overlay_box: VBoxContainer
var pause_banner: Control
var pause_box: VBoxContainer
var icon_texture_cache := {}
var relic_signature := ""


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
	var wave := int(data.get("wave", 1))
	var max_wave := int(data.get("max_wave", 0))
	if max_wave > 0:
		wave_label.text = "공세 %d/%d" % [wave, max_wave]
	else:
		wave_label.text = "공세 %d" % wave
	var wallets: Dictionary = data.get("wallets", {})
	var registry: Dictionary = data.get("currency_registry", {})
	for currency_id in wallet_labels.keys():
		var entry: Dictionary = wallets.get(str(currency_id), {})
		var definition: Dictionary = registry.get(str(currency_id), {})
		var short_name := str(definition.get("short_name", currency_id))
		wallet_labels[currency_id].text = "%s %d" % [short_name, int(entry.get("balance", 0))]
	time_label.text = str(data.get("time", "00:00"))
	var relics: Array = data.get("relics", [])
	render_relics(relics)
	var risk_lines: PackedStringArray = data.get("risk_lines", PackedStringArray())
	var risk_text := "\n".join(risk_lines)
	if risk_label.text != risk_text:
		risk_label.text = risk_text
	var risk_visible := not risk_lines.is_empty()
	if risk_panel.visible != risk_visible:
		risk_panel.visible = risk_visible


func render_weapons(weapons: Array, damage_multiplier: float) -> void:
	_clear_children(weapon_box)
	if weapons.is_empty():
		var empty := _make_label("무기 없음", 13, OreUITheme.MUTED)
		weapon_box.add_child(empty)
		return

	for weapon in weapons:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(188, 42)
		card.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.12, 0.13, 0.11, 0.88), OreUITheme.LINE, 8, 1))
		weapon_box.add_child(card)

		var margin := _margin(7, 6, 10, 6)
		card.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		margin.add_child(row)

		var icon_path := str(Dictionary(weapon).get("icon", ""))
		if not icon_path.is_empty():
			row.add_child(_make_plain_icon(icon_path, 32))

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(box)

		var title := _make_label(str(weapon["name"]), 12, OreUITheme.INK)
		title.clip_text = true
		var mods: Array = weapon.get("mods", [])
		var temper_rank := int(weapon.get("upgrade_rank", 0))
		var detail_text := "부품 %d · 단련 %s · 피해 %d" % [mods.size(), _roman_rank(temper_rank), int(round(float(weapon["damage"]) * damage_multiplier))]
		var detail := _make_label(detail_text, 11, OreUITheme.MUTED)
		detail.clip_text = true
		box.add_child(title)
		box.add_child(detail)


func render_relics(relics: Array) -> void:
	if relic_box == null:
		return
	var signature := _relic_signature(relics)
	if signature == relic_signature:
		return
	relic_signature = signature

	_clear_children(relic_box)
	relic_panel.visible = false
	for relic in relics:
		relic_box.add_child(_make_relic_icon(relic, 42))


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


func show_choice(eyebrow: String, title: String, options: Array, relics: Array = [], state_summary: Dictionary = {}) -> void:
	var tall := options.size() > 3
	var columns: int = 2 if options.size() > 6 else 3
	var card_height: int = 142 if tall else 126
	var checkpoint_options := _options_are_checkpoints(options)
	var shop_options := _options_are_shop(options)
	if checkpoint_options:
		columns = 2
		card_height = 164
	elif shop_options:
		columns = 3
		card_height = 142
	if _options_are_contracts(options):
		card_height = 158
	if _options_are_starter_weapons(options):
		card_height = 190
	_prepare_overlay(Vector2(1040 if checkpoint_options or shop_options else 900, 0), OreUITheme.PANEL_STRONG)
	overlay_box.add_child(_make_label(eyebrow, 14, OreUITheme.ORE))
	overlay_box.add_child(_make_label(title, 34, OreUITheme.INK))
	if not relics.is_empty():
		overlay_box.add_child(_make_relic_strip(relics, "현재 계약"))
	if not state_summary.is_empty() and not shop_options:
		overlay_box.add_child(_make_state_summary_panel(state_summary))

	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_box.add_child(grid)

	for option in options:
		grid.add_child(_make_option_card(option, card_height))

	overlay.visible = true


func _options_are_contracts(options: Array) -> bool:
	for option in options:
		if str(Dictionary(option).get("kind", "")) == "relic":
			return true
	return false


func _options_are_starter_weapons(options: Array) -> bool:
	for option in options:
		if str(Dictionary(option).get("kind", "")) == "starter_weapon":
			return true
	return false


func _options_are_checkpoints(options: Array) -> bool:
	for option in options:
		if str(Dictionary(option).get("kind", "")) == "checkpoint_route":
			return true
	return false


func _options_are_shop(options: Array) -> bool:
	for option in options:
		var kind := str(Dictionary(option).get("kind", ""))
		if ["part", "item", "heal", "temper"].has(kind) or str(Dictionary(option).get("id", "")) == "reroll":
			return true
	return false


func show_end(eyebrow: String, title: String, body: String, button_text: String, relics: Array = []) -> void:
	_prepare_overlay(Vector2(760, 0), OreUITheme.PANEL_STRONG)
	overlay_box.add_child(_make_label(eyebrow, 14, OreUITheme.ORE))
	overlay_box.add_child(_make_label(title, 40, OreUITheme.INK))

	var body_label := _make_label(body, 16, OreUITheme.MUTED)
	body_label.custom_minimum_size = Vector2(660, 138)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_box.add_child(body_label)
	if not relics.is_empty():
		overlay_box.add_child(_make_relic_strip(relics, "이번 런 계약"))

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


func show_pause(state_summary: Dictionary, relics: Array = []) -> void:
	_clear_children(pause_box)
	var title := _make_label("일시 정지", 34, OreUITheme.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_box.add_child(title)
	if not relics.is_empty():
		pause_box.add_child(_make_relic_strip(relics, "현재 계약"))
	pause_box.add_child(_make_state_summary_panel(state_summary))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	pause_box.add_child(buttons)

	var resume_button := Button.new()
	resume_button.text = "계속"
	resume_button.custom_minimum_size = Vector2(150, 42)
	resume_button.pressed.connect(func(): resume_requested.emit())
	buttons.add_child(resume_button)

	var restart_button := Button.new()
	restart_button.text = "다시 시작"
	restart_button.custom_minimum_size = Vector2(150, 42)
	restart_button.pressed.connect(func(): restart_requested.emit())
	buttons.add_child(restart_button)
	pause_banner.visible = true


func hide_pause() -> void:
	pause_banner.visible = false


func _build_hud() -> void:
	top_panel = PanelContainer.new()
	top_panel.name = "TopHud"
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 12
	top_panel.offset_top = 12
	top_panel.offset_right = -12
	top_panel.offset_bottom = 70
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.08, 0.09, 0.075, 0.54), Color(0.46, 0.41, 0.31, 0.46), 8, 1))
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
	wallet_labels = {
		"ore": _stat_pill("광 0", OreUITheme.ORE),
		"catalyst": _stat_pill("촉 0", OreUITheme.AQUA),
		"forge_core": _stat_pill("핵 0", OreUITheme.EMBER),
	}
	for currency_id in wallet_labels.keys():
		wallet_labels[currency_id].custom_minimum_size = Vector2(64, 42)
	time_label = _stat_pill("00:00", OreUITheme.MUTED)
	stats.add_child(wave_label)
	for currency_id in ["ore", "catalyst", "forge_core"]:
		stats.add_child(wallet_labels[currency_id])
	stats.add_child(time_label)

	weapon_panel = PanelContainer.new()
	weapon_panel.name = "WeaponHud"
	weapon_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	weapon_panel.offset_left = 12
	weapon_panel.offset_top = -66
	weapon_panel.offset_right = 960
	weapon_panel.offset_bottom = -12
	weapon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.10, 0.11, 0.09, 0.84), OreUITheme.LINE, 8, 1))
	weapon_panel.visible = false
	root.add_child(weapon_panel)

	var weapon_margin := _margin(10, 7, 10, 7)
	weapon_panel.add_child(weapon_margin)
	weapon_box = HBoxContainer.new()
	weapon_box.add_theme_constant_override("separation", 8)
	weapon_margin.add_child(weapon_box)

	relic_panel = PanelContainer.new()
	relic_panel.name = "RelicHud"
	relic_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	relic_panel.offset_left = -324
	relic_panel.offset_top = -66
	relic_panel.offset_right = -12
	relic_panel.offset_bottom = -12
	relic_panel.visible = false
	relic_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.10, 0.11, 0.09, 0.84), OreUITheme.LINE, 8, 1))
	root.add_child(relic_panel)

	var relic_margin := _margin(10, 7, 10, 7)
	relic_panel.add_child(relic_margin)
	relic_box = HBoxContainer.new()
	relic_box.add_theme_constant_override("separation", 7)
	relic_margin.add_child(relic_box)

	risk_panel = PanelContainer.new()
	risk_panel.name = "RiskHud"
	risk_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	risk_panel.offset_left = 12
	risk_panel.offset_top = 78
	risk_panel.offset_right = 520
	risk_panel.offset_bottom = 168
	risk_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	risk_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.12, 0.08, 0.06, 0.88), Color(0.66, 0.38, 0.22, 0.88), 8, 1))
	root.add_child(risk_panel)
	var risk_margin := _margin(10, 7, 10, 7)
	risk_panel.add_child(risk_margin)
	risk_label = _make_label("", 12, OreUITheme.INK)
	risk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	risk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	risk_margin.add_child(risk_label)


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
	pause_banner = Control.new()
	pause_banner.name = "PauseOverlay"
	pause_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_banner.visible = false
	root.add_child(pause_banner)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.42)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_banner.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_banner.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.06, 0.065, 0.055, 0.94), OreUITheme.LINE_STRONG, 8, 1))
	center.add_child(panel)

	var margin := _margin(24, 20, 24, 20)
	panel.add_child(margin)

	pause_box = VBoxContainer.new()
	pause_box.add_theme_constant_override("separation", 12)
	pause_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(pause_box)


func _prepare_overlay(size: Vector2, color: Color) -> void:
	_clear_children(overlay_box)
	overlay_panel.custom_minimum_size = size
	overlay_panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(color, OreUITheme.LINE_STRONG, 8, 1))


func _make_relic_strip(relics: Array, title: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := _make_label(title, 13, OreUITheme.MUTED)
	label.custom_minimum_size = Vector2(78, 42)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	for relic in relics:
		row.add_child(_make_relic_icon(relic, 42))
	return row


func _make_state_summary_panel(state_summary: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.08, 0.09, 0.075, 0.62), Color(0.34, 0.31, 0.24, 0.58), 8, 1))

	var margin := _margin(12, 10, 12, 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	if state_summary.has("weapon_icon"):
		var weapon_row := HBoxContainer.new()
		weapon_row.add_theme_constant_override("separation", 8)
		weapon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_path := str(state_summary.get("weapon_icon", ""))
		if not icon_path.is_empty():
			weapon_row.add_child(_make_plain_icon(icon_path, 34))
		var weapon_label := _make_label(str(state_summary.get("weapon_label", "현재 무기")), 13, OreUITheme.INK)
		weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		weapon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weapon_row.add_child(weapon_label)
		box.add_child(weapon_row)

	var lines: PackedStringArray = state_summary.get("lines", PackedStringArray())
	for i in range(lines.size()):
		var color := OreUITheme.INK if i == 0 else OreUITheme.MUTED
		var label := _make_label(lines[i], 13, color)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(520, 20)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(label)
	return panel


func _make_plain_icon(icon_path: String, size: int) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(size, size)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.08, 0.09, 0.075, 0.80), Color(0.36, 0.33, 0.25, 0.74), 7, 1))

	var margin := _margin(3, 3, 3, 3)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(margin)

	var icon := TextureRect.new()
	icon.texture = _load_png_texture(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(size - 6, size - 6)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(icon)
	return frame


func _make_relic_icon(relic: Dictionary, size: int) -> Control:
	var shell := Control.new()
	shell.custom_minimum_size = Vector2(size, size)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.08, 0.09, 0.075, 0.82), Color(0.42, 0.36, 0.24, 0.82), 7, 1))
	shell.add_child(frame)

	var margin := _margin(4, 4, 4, 4)
	frame.add_child(margin)

	var icon := TextureRect.new()
	icon.texture = _load_png_texture(str(relic.get("icon", "")))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(size - 8, size - 8)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(icon)

	var count := int(relic.get("count", 1))
	if count > 1:
		var badge := PanelContainer.new()
		badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left = -24
		badge.offset_top = -18
		badge.offset_right = 2
		badge.offset_bottom = 2
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.12, 0.09, 0.06, 0.96), OreUITheme.ORE, 5, 1))
		shell.add_child(badge)

		var badge_label := _make_label("x%d" % count, 10, OreUITheme.INK)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(badge_label)

	return shell


func _make_option_card(option: Dictionary, min_height: int) -> Control:
	var disabled := bool(option.get("disabled", false))
	var rarity := str(option.get("rarity", ""))
	var card := Control.new()
	card.custom_minimum_size = Vector2(0, min_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("normal", disabled, rarity))
	card.add_child(panel)

	var margin := _margin(14, 12, 14, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var icon_path := str(option.get("icon", ""))
	if icon_path.is_empty():
		margin.add_child(box)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(row)

		var icon_frame := PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(76, 76)
		icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_theme_stylebox_override("panel", OreUITheme.panel_style(Color(0.08, 0.09, 0.075, 0.76), Color(0.36, 0.33, 0.25, 0.76), 8, 1))
		row.add_child(icon_frame)

		var icon_margin := _margin(5, 5, 5, 5)
		icon_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_child(icon_margin)

		var icon := TextureRect.new()
		icon.texture = _load_png_texture(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(66, 66)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_margin.add_child(icon)

		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(box)

	var title_color := OreUITheme.DIM if disabled else OreUITheme.INK
	var desc_color := Color(0.58, 0.55, 0.49, 0.72) if disabled else OreUITheme.MUTED
	var meta_color := Color(0.72, 0.66, 0.52, 0.56) if disabled else OreUITheme.ORE
	if not rarity.is_empty() and not disabled:
		meta_color = OreUITheme.rarity_color(rarity)

	if not rarity.is_empty():
		var badge := _make_label(_rarity_label(rarity), 11, meta_color)
		badge.clip_text = true
		badge.custom_minimum_size = Vector2(0, 16)
		box.add_child(badge)

	var title := _make_label(str(option.get("name", "")), 18 if min_height > 120 else 15, title_color)
	title.clip_text = true
	title.custom_minimum_size = Vector2(0, 26 if min_height > 120 else 22)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(title)

	var desc := _make_label(str(option.get("desc", "")), 13, desc_color)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var desc_height := 32
	if min_height > 170:
		desc_height = 88
	elif min_height > 120:
		desc_height = 48
	desc.custom_minimum_size = Vector2(0, desc_height)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	box.add_child(desc)

	var meta := _make_label(str(option.get("meta_text", "")), 12, meta_color)
	if str(option.get("kind", "")) == "relic" or str(option.get("kind", "")) == "checkpoint_route":
		meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		meta.custom_minimum_size = Vector2(0, 34)
	else:
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
		hit_area.mouse_entered.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("hover", false, rarity)))
		hit_area.mouse_exited.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("normal", false, rarity)))
		hit_area.button_down.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("pressed", false, rarity)))
		hit_area.button_up.connect(func(): panel.add_theme_stylebox_override("panel", OreUITheme.option_card_style("hover", false, rarity)))
		hit_area.pressed.connect(func(): option_selected.emit(option))
		card.add_child(hit_area)
	return card


func _rarity_label(rarity: String) -> String:
	match rarity:
		"rare":
			return "RARE"
		"legendary":
			return "LEGENDARY"
		_:
			return "COMMON"


func _load_png_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if icon_texture_cache.has(path):
		return icon_texture_cache[path]
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	icon_texture_cache[path] = texture
	return texture


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


func _relic_signature(relics: Array) -> String:
	var parts := PackedStringArray()
	for relic in relics:
		parts.append("%s:%d" % [str(relic.get("id", "")), int(relic.get("count", 1))])
	return "|".join(parts)


func _roman_rank(rank: int) -> String:
	match rank:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		_:
			return "0"
