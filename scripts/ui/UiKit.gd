class_name UiKit
extends RefCounted
## UI 设计系统：配色、字体、主题、面板、按钮、立绘/背景/CG 加载。
##
## 字体分工：
##   思源宋体（Noto Serif SC）—— 叙事：NPC 对话、剧情旁白、人物姓名、地点标题
##   思源黑体（Noto Sans SC） —— 操作：任务、按钮、证据、系统反馈、输入框、帮助说明、时间、行动次数

# ---------------------------------------------------------------- 配色
const C_BG := Color("#120e17")          # 最深的底色
const C_PANEL := Color("#1b1621")       # 面板
const C_PANEL_2 := Color("#262030")     # 按钮 / 次级面板
const C_BORDER := Color("#5e4c34")      # 青铜描边
const C_GOLD := Color("#e6bd62")        # 金色强调（标题、姓名）
const C_GOLD_DIM := Color("#a8884c")
const C_TEXT := Color("#efe6d4")        # 羊皮纸白
const C_DIM := Color("#a59b8b")         # 暖灰说明文字
const C_RED := Color("#e2715d")
const C_GREEN := Color("#8fc284")
const C_BLUE := Color("#93b6e2")
const C_PURPLE := Color("#c4a3e6")

const TACTIC_COLORS := {
	"说服": Color("#8fc284"), "转移": Color("#93b6e2"), "表演": Color("#e6bd62"),
	"撒谎": Color("#e8955a"), "坦白": Color("#ef8db0"), "威胁": Color("#e2715d"), "交易": Color("#b9a0ea"),
}
const STANCE_COLORS := {
	"崇拜": Color("#f0a8d2"), "合作": Color("#8fc284"), "观望": Color("#c8c0b4"),
	"试探": Color("#e6bd62"), "敌对": Color("#e2715d"), "共犯": Color("#b9a0ea"),
}

# 时段色调：上午 / 下午 / 傍晚 / 夜晚
const SLOT_TINTS := [Color(1, 1, 1), Color(1, 0.95, 0.86), Color(1, 0.76, 0.6), Color(0.42, 0.48, 0.78)]

# ---------------------------------------------------------------- 字体
const FONT_DIR := "res://assets/fonts/"
const SERIF := FONT_DIR + "serif_regular.tres"     # 思源宋体 Medium 500：正文叙事
const SERIF_BOLD := FONT_DIR + "serif_bold.tres"   # 思源宋体 Bold 700：姓名、地点、标题
const SERIF_BLACK := FONT_DIR + "serif_black.tres" # 思源宋体 Black 900：Logo
const SANS := FONT_DIR + "sans_regular.tres"       # 思源黑体 Regular 400：说明、反馈、输入
const SANS_MEDIUM := FONT_DIR + "sans_medium.tres" # 思源黑体 Medium 500：按钮
const SANS_BOLD := FONT_DIR + "sans_bold.tres"     # 思源黑体 Bold 700：时间、数值强调

static var _cache := {}


static func font(path: String) -> Font:
	if _cache.has(path):
		return _cache[path]
	var f: Font = null
	if ResourceLoader.exists(path):
		f = load(path)
	if f == null:
		var sf := SystemFont.new()
		var serif := path.contains("serif")
		sf.font_names = PackedStringArray(["Noto Serif SC", "Source Han Serif SC", "SimSun"] if serif else ["Noto Sans SC", "Source Han Sans SC", "Microsoft YaHei UI", "Microsoft YaHei"])
		sf.font_weight = 700 if path.contains("bold") else (900 if path.contains("black") else 400)
		f = sf
	_cache[path] = f
	return f


## BBCode 里切换字体用，例如 "[font=%s]……[/font]" % UiKit.SANS
static func bb_sans(text: String, size: int = 0, col: Color = Color(0, 0, 0, 0)) -> String:
	var s := text
	if col.a > 0:
		s = "[color=#%s]%s[/color]" % [col.to_html(false), s]
	if size > 0:
		s = "[font_size=%d]%s[/font_size]" % [size, s]
	return "[font=%s]%s[/font]" % [SANS, s]


static func hex(c: Color) -> String:
	return "#" + c.to_html(false)


# ---------------------------------------------------------------- 主题

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font(SANS)
	t.default_font_size = 17

	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))

	# 富文本默认是叙事文字（宋体）；系统类文字用 rich(false) 切到黑体
	t.set_font("normal_font", "RichTextLabel", font(SERIF))
	t.set_font("bold_font", "RichTextLabel", font(SERIF_BOLD))
	t.set_font("italics_font", "RichTextLabel", font(SERIF))
	t.set_font("bold_italics_font", "RichTextLabel", font(SERIF_BOLD))
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_constant("line_separation", "RichTextLabel", 5)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	t.set_stylebox("focus", "RichTextLabel", StyleBoxEmpty.new())

	# 按钮
	t.set_font("font", "Button", font(SANS_MEDIUM))
	t.set_font_size("font_size", "Button", 17)
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_GOLD)
	t.set_color("font_pressed_color", "Button", C_GOLD)
	t.set_color("font_focus_color", "Button", C_TEXT)
	t.set_color("font_hover_pressed_color", "Button", C_GOLD)
	t.set_color("font_disabled_color", "Button", Color("#6d6576"))
	t.set_stylebox("normal", "Button", btn_style(Color(C_PANEL_2, 0.92), C_BORDER))
	t.set_stylebox("hover", "Button", btn_style(Color("#352b3e"), C_GOLD))
	t.set_stylebox("pressed", "Button", btn_style(Color("#1a1420"), C_GOLD))
	t.set_stylebox("hover_pressed", "Button", btn_style(Color("#1a1420"), C_GOLD))
	t.set_stylebox("disabled", "Button", btn_style(Color(C_PANEL, 0.7), Color("#3a3240")))
	t.set_stylebox("focus", "Button", btn_style(Color(0, 0, 0, 0), Color(C_GOLD, 0.7), 1, true))
	t.set_constant("h_separation", "Button", 8)

	t.set_font("font", "CheckBox", font(SANS))
	t.set_color("font_color", "CheckBox", C_DIM)
	t.set_color("font_hover_color", "CheckBox", C_TEXT)
	t.set_color("font_pressed_color", "CheckBox", C_TEXT)

	# 面板
	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("panel", "Panel", panel_style())

	# 输入框
	t.set_font("font", "LineEdit", font(SANS))
	t.set_font_size("font_size", "LineEdit", 17)
	var le := btn_style(Color("#0d0a11", 0.95), C_BORDER)
	le.content_margin_left = 14
	t.set_stylebox("normal", "LineEdit", le)
	var lef := le.duplicate()
	lef.border_color = C_GOLD
	t.set_stylebox("focus", "LineEdit", lef)
	var led := le.duplicate()
	led.bg_color = Color("#141018", 0.8)
	led.border_color = Color("#3a3240")
	t.set_stylebox("read_only", "LineEdit", led)
	t.set_color("font_color", "LineEdit", C_TEXT)
	t.set_color("font_uneditable_color", "LineEdit", Color("#7a7282"))
	t.set_color("font_placeholder_color", "LineEdit", Color("#7d7468"))
	t.set_color("caret_color", "LineEdit", C_GOLD)
	t.set_color("selection_color", "LineEdit", Color(C_GOLD, 0.3))

	# 进度条（疑云值）
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color("#0d0a11", 0.9)
	pbg.border_color = Color("#3e3346")
	pbg.set_border_width_all(1)
	pbg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = C_RED
	fill.set_corner_radius_all(4)
	t.set_stylebox("background", "ProgressBar", pbg)
	t.set_stylebox("fill", "ProgressBar", fill)

	# 分页（手记）
	t.set_font("font", "TabContainer", font(SANS_MEDIUM))
	t.set_font_size("font_size", "TabContainer", 17)
	t.set_color("font_selected_color", "TabContainer", C_GOLD)
	t.set_color("font_unselected_color", "TabContainer", C_DIM)
	t.set_color("font_hovered_color", "TabContainer", C_TEXT)
	var tab_sel := StyleBoxFlat.new()
	tab_sel.bg_color = Color(C_PANEL_2, 0.95)
	tab_sel.border_color = C_GOLD
	tab_sel.border_width_bottom = 2
	tab_sel.set_corner_radius_all(3)
	tab_sel.corner_radius_bottom_left = 0
	tab_sel.corner_radius_bottom_right = 0
	_margins(tab_sel, 18, 8)
	var tab_un := tab_sel.duplicate()
	tab_un.bg_color = Color(0, 0, 0, 0)
	tab_un.border_color = Color(0, 0, 0, 0)
	var tab_hover := tab_un.duplicate()
	tab_hover.bg_color = Color(C_PANEL_2, 0.5)
	t.set_stylebox("tab_selected", "TabContainer", tab_sel)
	t.set_stylebox("tab_unselected", "TabContainer", tab_un)
	t.set_stylebox("tab_hovered", "TabContainer", tab_hover)
	t.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	var tpanel := StyleBoxFlat.new()
	tpanel.bg_color = Color("#0f0c13", 0.55)
	tpanel.border_color = Color("#3e3346")
	tpanel.border_width_top = 1
	_margins(tpanel, 18, 14)
	t.set_stylebox("panel", "TabContainer", tpanel)

	# 分隔线
	var sep := StyleBoxLine.new()
	sep.color = Color(C_BORDER, 0.8)
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 12)

	# 滚动条：细
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(C_GOLD_DIM, 0.45)
	grab.set_corner_radius_all(3)
	grab.content_margin_left = 3
	grab.content_margin_right = 3
	var grab_h := grab.duplicate()
	grab_h.bg_color = Color(C_GOLD, 0.7)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.18)
	track.set_corner_radius_all(3)
	track.content_margin_left = 3
	track.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_h)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_h)

	# 提示框
	var tip := panel_style(Color("#0d0a11"), C_BORDER, 0.96)
	_margins(tip, 10, 6)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_font("font", "TooltipLabel", font(SANS))
	t.set_font_size("font_size", "TooltipLabel", 15)
	t.set_color("font_color", "TooltipLabel", C_TEXT)

	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("separation", "VBoxContainer", 8)
	return t


static func _margins(s: StyleBox, h: float, v: float) -> void:
	s.content_margin_left = h
	s.content_margin_right = h
	s.content_margin_top = v
	s.content_margin_bottom = v


static func panel_style(col: Color = C_PANEL, border: Color = C_BORDER, alpha: float = 0.92) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(col, alpha)
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 14
	s.anti_aliasing = true
	_margins(s, 20, 16)
	return s


static func btn_style(col: Color, border: Color, bw: int = 1, draw_center_off: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.draw_center = not draw_center_off
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(4)
	_margins(s, 16, 7)
	return s


## 小标签（态度、状态）
static func chip(text: String, col: Color, size: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(col, 0.16)
	s.border_color = Color(col, 0.7)
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	_margins(s, 9, 1)
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text, size, col)
	p.add_child(l)
	return p


# ---------------------------------------------------------------- 文字

## 操作类文字（黑体）
static func label(text: String, size: int = 17, col: Color = C_TEXT, path: String = SANS) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(path))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap_label(text: String, size: int = 17, col: Color = C_TEXT, path: String = SANS) -> Label:
	var l := label(text, size, col, path)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## 叙事类文字（宋体）
static func serif_label(text: String, size: int = 18, col: Color = C_TEXT, bold: bool = false) -> Label:
	return label(text, size, col, SERIF_BOLD if bold else SERIF)


## 姓名、地点、标题（宋体粗体 + 投影）
static func title_label(text: String, size: int = 28, col: Color = C_GOLD) -> Label:
	var l := label(text, size, col, SERIF_BOLD)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 4)
	return l


## 富文本。serif=true 用于叙事（默认），false 用于系统文字。
static func rich(serif: bool = true, size: int = 18) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	if not serif:
		r.add_theme_font_override("normal_font", font(SANS))
		r.add_theme_font_override("bold_font", font(SANS_BOLD))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	return r


static func button(text: String, cb: Callable, size: int = 17) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	return b


## 主要按钮（金色描边，更醒目）
static func primary_button(text: String, cb: Callable, size: int = 18) -> Button:
	var b := button(text, cb, size)
	b.add_theme_stylebox_override("normal", btn_style(Color("#3a2c1c", 0.95), C_GOLD))
	b.add_theme_stylebox_override("hover", btn_style(Color("#4c3a22"), Color("#ffd98a")))
	b.add_theme_color_override("font_color", Color("#ffe7b0"))
	return b


# ---------------------------------------------------------------- 图片

static func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img:
			img.generate_mipmaps()
			return ImageTexture.create_from_image(img)
	return null


static func _cached_tex(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = _load_tex(path)
	return _cache[path]


static func _portrait_config() -> Dictionary:
	if not _cache.has("_portrait_config"):
		var cfg = null
		var f := FileAccess.open("res://assets/portraits/portraits.json", FileAccess.READ)
		if f:
			cfg = JSON.parse_string(f.get_as_text())
		_cache["_portrait_config"] = cfg if cfg is Dictionary else {}
	return _cache["_portrait_config"]


## 单张立绘（assets/portraits/<id>.png）。没有时返回 null。
static func full_portrait(npc_id: String) -> Texture2D:
	return _cached_tex("res://assets/portraits/%s.png" % npc_id)


static func has_full_portrait(npc_id: String) -> bool:
	return full_portrait(npc_id) != null


## 立绘：优先用单张立绘（不分表情）；没有时退回到按表情区分的占位图。
static func portrait(npc_id: String, emotion: String = "neutral") -> Texture2D:
	var full := full_portrait(npc_id)
	if full:
		return full
	var tex := _cached_tex("res://assets/portraits/%s/%s.png" % [npc_id, emotion])
	if tex == null and emotion != "neutral":
		tex = portrait(npc_id, "neutral")
	return tex


## 小头像：从单张立绘里按 portraits.json 的 face 裁出头部。
static func face(npc_id: String, emotion: String = "neutral") -> Texture2D:
	var full := full_portrait(npc_id)
	if full == null:
		return portrait(npc_id, emotion)
	var key := npc_id + "/_face"
	if not _cache.has(key):
		var w := float(full.get_width())
		var h := float(full.get_height())
		var fc: Array = _portrait_config().get(npc_id, {}).get("face", [0.5, 0.05, 0.36])
		var s := w * float(fc[2])
		var at := AtlasTexture.new()
		at.atlas = full
		at.region = Rect2(clampf(w * float(fc[0]) - s / 2.0, 0.0, w - s), h * float(fc[1]), s, s)
		_cache[key] = at
	return _cache[key]


## px 是宽度。px <= 96 时显示裁切的小头像（正方形），否则显示 2:3 的整张立绘。
static func portrait_rect(npc_id: String, px: int, emotion: String = "neutral") -> TextureRect:
	var r := TextureRect.new()
	var small := px <= 96
	r.texture = face(npc_id, emotion) if small else portrait(npc_id, emotion)
	r.custom_minimum_size = Vector2(px, px) if small else Vector2(px, roundi(px * 1.5))
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 带边框的小头像
static func face_badge(npc_id: String, px: int, border: Color = C_BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#2a2230")
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(1)
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 头像是 1:1 的裁切图；放进 HBox/VBox 时不能被行高（或列宽）拉伸成 2:3 的长框
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.add_child(portrait_rect(npc_id, px))
	return p


## 地点背景：assets/backgrounds/<loc_id>_night.png（夜晚，可选）或 <loc_id>.png。
static func location_bg(loc_id: String, night: bool) -> Texture2D:
	if night:
		var n := _cached_tex("res://assets/backgrounds/%s_night.png" % loc_id)
		if n:
			return n
	return _cached_tex("res://assets/backgrounds/%s.png" % loc_id)


static func has_night_art(loc_id: String) -> bool:
	return _cached_tex("res://assets/backgrounds/%s_night.png" % loc_id) != null


static func cg(id: String) -> Texture2D:
	return _cached_tex("res://assets/cg/%s.png" % id)


static func town_map() -> Texture2D:
	var t := _cached_tex("res://assets/tiles/town_map.png")
	return t if t else _cached_tex("res://assets/tiles/town.png")


## 场景 id → 图片："map" = 王都地图；"cg:<id>" = CG；其他 = 地点背景
static func scene_tex(id: String, night: bool = false) -> Texture2D:
	if id == "":
		return null
	if id == "map":
		return town_map()
	if id.begins_with("cg:"):
		return cg(id.trim_prefix("cg:"))
	return location_bg(id, night)


## 全屏铺满的背景图
static func cover_rect(tex: Texture2D, tint: Color = Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 渐变遮罩。dir: "bottom" / "top" / "left" / "right" 表示哪一侧最暗。
static func gradient_rect(dir: String, max_alpha: float = 0.85, col: Color = C_BG, start: float = 0.0) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.set_color(1, Color(col, max_alpha))
	g.set_offset(0, start)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 64
	gt.height = 64
	match dir:
		"bottom":
			gt.fill_from = Vector2(0, 0)
			gt.fill_to = Vector2(0, 1)
		"top":
			gt.fill_from = Vector2(0, 1)
			gt.fill_to = Vector2(0, 0)
		"left":
			gt.fill_from = Vector2(1, 0)
			gt.fill_to = Vector2(0, 0)
		_:
			gt.fill_from = Vector2(0, 0)
			gt.fill_to = Vector2(1, 0)
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 四周压暗的暗角
static func vignette(alpha: float = 0.55) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, alpha))
	g.set_offset(0, 0.55)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	gt.width = 128
	gt.height = 128
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func dim_layer(alpha: float = 0.6) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.03, 0.02, 0.05, alpha)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	return c


static func centered_panel(parent: Control, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = size
	p.position = (Vector2(1280, 720) - size) / 2.0
	p.size = size
	parent.add_child(p)
	return p


static func stance_bbcode(stance: String) -> String:
	var c: Color = STANCE_COLORS.get(stance, C_TEXT)
	return "[color=#%s]%s[/color]" % [c.to_html(false), stance]


static func stance_color(stance: String) -> Color:
	return STANCE_COLORS.get(stance, C_TEXT)


## 角色状态标签（加入讨伐队 / 答应相助 / 知道真相）
static func npc_tags(n: NpcState) -> Array:
	var res: Array = []
	if bool(n.flags.get("joined", false)):
		res.append(["已加入讨伐队", C_GREEN])
	if bool(n.flags.get("promised_help", false)):
		res.append(["答应暗中相助", C_BLUE])
	if bool(n.flags.get("knows_truth", false)):
		res.append(["知道你没有神力", Color("#ef8db0")])
	return res


## 把剧情文本里的旧色值换成新配色；红 / 绿 / 灰三种颜色属于系统反馈，同时换成黑体。
static func restyle(s: String) -> String:
	s = s.replace("[color=#e0b040]", "[color=%s]" % hex(C_GOLD))
	var map := {"e06060": C_RED, "70c080": C_GREEN, "a89fb8": C_DIM}
	for old in map:
		if not _cache.has("re_" + old):
			var re := RegEx.new()
			re.compile(r"\[color=#" + old + r"\]([\s\S]*?)\[/color\]")
			_cache["re_" + old] = re
		var r: RegEx = _cache["re_" + old]
		s = r.sub(s, "[font=%s][color=%s]$1[/color][/font]" % [SANS, hex(map[old])], true)
	return s
