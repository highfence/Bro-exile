extends RefCounted

class_name OreUITheme

const FONT_PATH := "res://assets/fonts/PretendardVariable.ttf"

const INK := Color("#f5efe3")
const MUTED := Color("#b7ad9b")
const DIM := Color("#837969")
const PANEL := Color(0.10, 0.11, 0.09, 0.90)
const PANEL_STRONG := Color(0.14, 0.15, 0.12, 0.98)
const PANEL_SOFT := Color(0.18, 0.19, 0.15, 0.86)
const LINE := Color(0.96, 0.91, 0.82, 0.18)
const LINE_STRONG := Color(0.96, 0.91, 0.82, 0.30)
const ORE := Color("#e6b85c")
const EMBER := Color("#f0643b")
const ACID := Color("#93c96d")
const AQUA := Color("#6cc3c0")
const DARK := Color("#17120a")
const SHADE := Color(0.03, 0.035, 0.03, 0.70)


static func load_font() -> Font:
	if not ensure_text_rendering_available():
		push_warning("현재 Godot 빌드는 TextServerDummy만 사용 중이라 Label/Button 텍스트를 렌더링할 수 없습니다. module_text_server_fb_enabled=yes로 엔진을 다시 빌드해야 합니다.")
		return SystemFont.new()
	if ResourceLoader.exists(FONT_PATH):
		var font := load(FONT_PATH)
		if font is Font:
			return font
	if FileAccess.file_exists(FONT_PATH):
		var font_file := FontFile.new()
		if font_file.load_dynamic_font(FONT_PATH) == OK:
			return font_file
	push_warning("UI 폰트를 불러오지 못했습니다: %s" % FONT_PATH)
	return SystemFont.new()


static func text_rendering_available() -> bool:
	return _can_render_text(TextServerManager.get_primary_interface())


static func ensure_text_rendering_available() -> bool:
	if text_rendering_available():
		return true
	for i in range(TextServerManager.get_interface_count()):
		var server := TextServerManager.get_interface(i)
		if _can_render_text(server):
			TextServerManager.set_primary_interface(server)
			return true
	return false


static func _can_render_text(server: TextServer) -> bool:
	return server != null and server.get_class() != "TextServerDummy" and server.get_name() != "Dummy"


static func create_theme(font: Font) -> Theme:
	var theme := Theme.new()
	for type_name in ["Label", "Button", "ProgressBar", "RichTextLabel", "LineEdit"]:
		theme.set_font("font", type_name, font)

	theme.set_font_size("font_size", "Label", 16)
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.62))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_font_size("font_size", "Button", 16)
	theme.set_color("font_color", "Button", DARK)
	theme.set_color("font_hover_color", "Button", DARK)
	theme.set_color("font_pressed_color", "Button", DARK)
	theme.set_color("font_disabled_color", "Button", Color(0.96, 0.91, 0.82, 0.44))
	theme.set_stylebox("normal", "Button", button_style(ORE, Color("#3b2c13")))
	theme.set_stylebox("hover", "Button", button_style(Color("#f0c76f"), Color("#4a3510")))
	theme.set_stylebox("pressed", "Button", button_style(EMBER, Color("#4a1e13")))
	theme.set_stylebox("disabled", "Button", button_style(Color(0.22, 0.22, 0.19, 0.82), Color(0.96, 0.91, 0.82, 0.12)))
	theme.set_stylebox("focus", "Button", focus_style())

	theme.set_stylebox("panel", "PanelContainer", panel_style(PANEL, LINE, 8, 1))
	theme.set_stylebox("background", "ProgressBar", meter_background())
	theme.set_stylebox("fill", "ProgressBar", meter_fill(ORE))
	return theme


static func panel_style(bg: Color, border: Color = LINE, radius: int = 8, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	_set_radius(style, radius)
	return style


static func card_style(disabled: bool = false) -> StyleBoxFlat:
	var bg := Color(0.13, 0.14, 0.12, 0.96)
	var border := LINE
	if disabled:
		bg = Color(0.10, 0.105, 0.095, 0.82)
		border = Color(0.96, 0.91, 0.82, 0.08)
	var style := panel_style(bg, border, 8, 1)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


static func option_card_style(state: String = "normal", disabled: bool = false) -> StyleBoxFlat:
	if disabled:
		return panel_style(Color(0.10, 0.105, 0.095, 0.82), Color(0.96, 0.91, 0.82, 0.08), 8, 1)
	if state == "pressed":
		return panel_style(Color(0.20, 0.17, 0.11, 0.98), ORE, 8, 1)
	if state == "hover":
		return panel_style(Color(0.17, 0.18, 0.145, 0.98), LINE_STRONG, 8, 1)
	return panel_style(Color(0.13, 0.14, 0.12, 0.96), LINE, 8, 1)


static func transparent_style() -> StyleBoxFlat:
	return panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0)


static func button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := panel_style(bg, border, 7, 1)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func subtle_button_style(bg: Color, border: Color = LINE) -> StyleBoxFlat:
	var style := panel_style(bg, border, 8, 1)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = AQUA
	style.set_border_width_all(2)
	_set_radius(style, 8)
	style.expand_margin_left = 2
	style.expand_margin_right = 2
	style.expand_margin_top = 2
	style.expand_margin_bottom = 2
	return style


static func meter_background() -> StyleBoxFlat:
	return panel_style(Color(0.03, 0.035, 0.03, 0.72), Color(0, 0, 0, 0), 99, 0)


static func meter_fill(color: Color) -> StyleBoxFlat:
	return panel_style(color, Color(0, 0, 0, 0), 99, 0)


static func _set_radius(style: StyleBoxFlat, radius: int) -> void:
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
