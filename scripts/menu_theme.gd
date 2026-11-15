extends RefCounted
## One restrained palette and type scale for every menu.
const INK := Color("101719")
const TEXT := Color("eef0e9")
const MUTED := Color("a9b5b7")
const LINE := Color("425055")
const ACCENT := Color("d5df88")
const PANEL := Color("1b2529")
const BODY = preload("res://assets/fonts/Barlow-Medium.ttf")
const HEADING = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")

static func box(color: Color, border: Color = LINE, radius: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

static func focus() -> StyleBoxFlat:
	var style := box(Color.TRANSPARENT, ACCENT)
	style.draw_center = false
	style.set_border_width_all(2)
	return style

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY
	theme.default_font_size = 18
	for type in ["Label", "Button", "OptionButton", "LineEdit", "PopupMenu"]:
		theme.set_font("font", type, BODY)
		theme.set_color("font_color", type, TEXT)
		theme.set_color("font_hover_color", type, TEXT)
		theme.set_color("font_focus_color", type, TEXT)
		theme.set_color("font_pressed_color", type, TEXT)
		theme.set_color("font_disabled_color", type, Color("758184"))
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, box(Color("1b2529")))
		theme.set_stylebox("hover", type, box(Color("303e43"), Color("768589")))
		theme.set_stylebox("pressed", type, box(Color("111c20"), ACCENT))
		theme.set_stylebox("disabled", type, box(Color("172024"), Color("303c40")))
		theme.set_stylebox("focus", type, focus())
		theme.set_font_size("font_size", type, 18)
	theme.set_stylebox("normal", "LineEdit", box(Color("131e22")))
	theme.set_stylebox("read_only", "LineEdit", box(Color("1b2529")))
	theme.set_stylebox("focus", "LineEdit", focus())
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("caret_color", "LineEdit", ACCENT)
	theme.set_color("selection_color", "LineEdit", Color("475651"))
	theme.set_stylebox("panel", "PopupMenu", box(Color("1b2529")))
	theme.set_stylebox("hover", "PopupMenu", box(Color("344448")))
	theme.set_constant("v_separation", "PopupMenu", 14)
	theme.set_stylebox("slider", "HSlider", box(Color("2d3b40"), Color("2d3b40")))
	theme.set_stylebox("grabber_area", "HSlider", box(ACCENT, ACCENT))
	theme.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT.lightened(0.12), ACCENT))
	return theme

static func primary(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		var color := ACCENT if state == "normal" else (Color("e5edb0") if state == "hover" else Color("b6c270"))
		button.add_theme_stylebox_override(state, box(color, color))
	var focus_style := focus()
	focus_style.border_color = TEXT
	focus_style.set_expand_margin_all(4)
	button.add_theme_stylebox_override("focus", focus_style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)

static func text_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := box(Color(0.12,0.17,0.19,0.7) if state in ["hover","pressed"] else Color.TRANSPARENT, Color.TRANSPARENT, 0)
		style.content_margin_left = 0
		style.content_margin_right = 0
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", MUTED)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
