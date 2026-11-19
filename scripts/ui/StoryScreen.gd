class_name StoryScreen
extends Control
## 预写的过场（开场、事件、夜间结算、结局）。逐页显示，点击 / 回车 / 空格继续。
## pages: [{title?, text, portrait?(npc_id), emotion?, cg?(id), scene?(地点id/"map"/"cg:<id>"), tint?: Color, bg?: Color, font?: "sans"}]
##   cg    —— 全屏 CG，文字框在底部
##   scene —— 压暗的场景背景，立绘站在左侧，文字框在右侧
## choices（可选，只在最后一页显示）：[{label, id, disabled?, tip?}]

signal finished(choice_id: String)

const CHARS_PER_SEC := 55.0
const PANEL_TOP_MARGIN := 30.0

var pages: Array = []
var choices: Array = []
var _idx := 0
var _bg: ColorRect
var _bg_img: TextureRect
var _shade: Control
var _portrait: TextureRect
var _panel: PanelContainer
var _title: Label
var _text: RichTextLabel
var _choice_box: VBoxContainer
var _next_btn: Button
var _page_label: Label
var _reveal := 0.0
var _fade: ColorRect
var _panel_bottom := 60.0


func setup(p: Array, c: Array = []) -> void:
	pages = p
	choices = c


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg = ColorRect.new()
	_bg.color = UiKit.C_BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_bg_img = UiKit.cover_rect(null)
	add_child(_bg_img)
	_shade = Control.new()
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	_title = UiKit.title_label("", 26)
	v.add_child(_title)
	_text = UiKit.rich(true, 19)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_constant_override("line_separation", 8)
	_text.add_theme_constant_override("paragraph_separation", 10)
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(_text)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 6)
	v.add_child(_choice_box)
	var row := HBoxContainer.new()
	_page_label = UiKit.label("", 13, UiKit.C_DIM)
	_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_page_label)
	_next_btn = UiKit.primary_button("继续 ▶", _on_next, 16)
	row.add_child(_next_btn)
	v.add_child(row)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.35)
	_show_page()


func _process(delta: float) -> void:
	if _text.visible_characters != -1:
		_reveal += delta
		var total := maxi(_text.get_total_character_count(), 1)
		_text.visible_characters = int(_reveal * CHARS_PER_SEC)
		if _text.visible_characters >= total:
			_text.visible_characters = -1


func _layout(mode: String) -> void:
	for c in _shade.get_children():
		c.queue_free()
	var ps := UiKit.panel_style(UiKit.C_PANEL, UiKit.C_BORDER, 0.9)
	var left := 200.0
	var right := 1080.0
	var bottom := 60.0
	match mode:
		"cg":
			_shade.add_child(UiKit.gradient_rect("bottom", 0.92, Color.BLACK, 0.5))
			ps.bg_color = Color(UiKit.C_BG, 0.62)
			ps.border_color = Color(UiKit.C_BORDER, 0.6)
			ps.content_margin_left = 34
			ps.content_margin_right = 34
			left = 40
			right = 1240
			bottom = 24
		"side":
			_shade.add_child(UiKit.vignette(0.65))
			_shade.add_child(UiKit.gradient_rect("right", 0.85, UiKit.C_BG, 0.35))
			left = 470
			right = 1240
			bottom = 50
		_:
			_shade.add_child(UiKit.vignette(0.7))
	_panel.add_theme_stylebox_override("panel", ps)
	# 贴底、向上生长，高度随文字变化
	_panel.anchor_left = 0
	_panel.anchor_right = 0
	_panel.anchor_top = 1
	_panel.anchor_bottom = 1
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = left
	_panel.offset_right = right
	_panel.offset_bottom = -bottom
	_panel.offset_top = -bottom
	_panel.custom_minimum_size = Vector2(0, 0 if mode == "cg" else 300)
	_panel_bottom = bottom
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2.ZERO


## 文字太多时（比如第一天夜里传闻很多），面板不能顶出屏幕：
## 把面板高度限制在屏幕内，正文改为可滚动。
func _fit_panel() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_panel):
		return
	var max_h := size.y - _panel_bottom - PANEL_TOP_MARGIN
	if _panel.size.y <= max_h:
		return
	var text_h := _text.size.y - (_panel.size.y - max_h)
	_text.fit_content = false
	_text.scroll_active = true
	_text.custom_minimum_size = Vector2(0, maxf(text_h, 80.0))
	_panel.offset_top = _panel.offset_bottom - max_h
	# 要滚动才能看全的长文不再逐字显示，免得后半段在可视区外“打字”
	_text.visible_characters = -1


func _show_page() -> void:
	var p: Dictionary = pages[_idx]
	var cg_id := str(p.get("cg", ""))
	var scene := str(p.get("scene", ""))
	var pid := str(p.get("portrait", ""))
	_bg.color = p.get("bg", UiKit.C_BG)
	var tint: Color = p.get("tint", Color.WHITE)
	var tex: Texture2D = null
	var mode := "plain"
	if cg_id != "" and UiKit.cg(cg_id):
		tex = UiKit.cg(cg_id)
		mode = "cg"
	else:
		tex = UiKit.scene_tex(scene, false)
		if tex:
			tint = tint * Color(0.62, 0.62, 0.62)
		if pid != "":
			mode = "side"
	_bg_img.texture = tex
	_bg_img.modulate = tint
	_layout(mode)

	_portrait.visible = mode == "side" and pid != ""
	if _portrait.visible:
		_portrait.texture = UiKit.portrait(pid, str(p.get("emotion", "neutral")))
		var small_art := not UiKit.has_full_portrait(pid)
		_portrait.position = Vector2(10, 40) if not small_art else Vector2(60, 180)
		_portrait.size = Vector2(450, 680) if not small_art else Vector2(360, 360)

	_title.text = str(p.get("title", ""))
	_title.visible = _title.text != ""
	var sans := str(p.get("font", "")) == "sans"
	_text.add_theme_font_override("normal_font", UiKit.font(UiKit.SANS if sans else UiKit.SERIF))
	_text.add_theme_font_override("bold_font", UiKit.font(UiKit.SANS_BOLD if sans else UiKit.SERIF_BOLD))
	_text.add_theme_font_size_override("normal_font_size", 18 if sans else 19)
	_text.add_theme_font_size_override("bold_font_size", 18 if sans else 19)
	_text.text = UiKit.restyle(_paragraphs(str(p.get("text", ""))))
	_text.scroll_to_line(0)
	_reveal = 0.0
	_text.visible_characters = 0
	_fit_panel()
	_page_label.text = "%d / %d" % [_idx + 1, pages.size()] if pages.size() > 1 else ""

	var last := _idx == pages.size() - 1
	for c in _choice_box.get_children():
		c.queue_free()
	if last and choices.size() > 0:
		_next_btn.visible = false
		for c in choices:
			var b := UiKit.button(c.label, func(): finished.emit(c.id), 16)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if c.get("disabled", false):
				b.disabled = true
				b.tooltip_text = c.get("tip", "")
			_choice_box.add_child(b)
	else:
		_next_btn.visible = true
		_next_btn.text = "继续 ▶" if not last else "确定"
		_next_btn.grab_focus.call_deferred()


## 剧情文本里用空行分段；这里把空行折成段落间距，排版更紧凑。
static func _paragraphs(s: String) -> String:
	while s.contains("\n\n\n"):
		s = s.replace("\n\n\n", "\n\n")
	return s.replace("\n\n", "\n")


func _on_next() -> void:
	if _text.visible_characters != -1:
		_text.visible_characters = -1
		return
	if _idx < pages.size() - 1:
		_idx += 1
		_show_page()
	else:
		finished.emit("")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _next_btn.visible:
		_on_next()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and _next_btn.visible:
		_on_next()
		get_viewport().set_input_as_handled()
