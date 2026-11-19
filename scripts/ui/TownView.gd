class_name TownView
extends Control
## 王都地图：顶部状态栏 + 可点击的地点；点进地点后显示地点场景和在场人物。

signal talk_requested(npc_id: String, loc_id: String)
signal location_action(action: String, loc_id: String)
signal rest_requested
signal journal_requested
signal menu_requested

const SCALE := 2
const TINTS := [Color(1, 1, 1), Color(1, 0.95, 0.86), Color(1, 0.76, 0.6), Color(0.42, 0.48, 0.78)]  # 同 UiKit.SLOT_TINTS

var _popup: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.cover_rect(UiKit.town_map(), TINTS[clampi(GameState.slot, 0, 3)]))
	add_child(UiKit.vignette(0.5))
	var band := ColorRect.new()
	band.color = Color(UiKit.C_BG, 0.78)
	band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	band.offset_bottom = 68
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	var top := UiKit.gradient_rect("top", 0.78, UiKit.C_BG, 0.0)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 68
	top.offset_bottom = 110
	add_child(top)
	var line := ColorRect.new()
	line.color = Color(UiKit.C_BORDER, 0.6)
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = 68
	line.offset_bottom = 69
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)

	for loc_id in GameState.locations:
		_add_hotspot(loc_id, GameState.locations[loc_id])

	_build_top_bar()
	_build_quest_panel()
	_show_toasts.call_deferred()

	var hint := UiKit.label("点击地点寻找角色　·　每个时段只能做一件事（深谈 / 调查 / 休息）　·　F1 调试面板", 14, Color(1, 1, 1, 0.8))
	hint.position = Vector2(20, 690)
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	hint.add_theme_constant_override("shadow_outline_size", 4)
	add_child(hint)


func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(20, 12)
	bar.size = Vector2(1240, 44)
	bar.add_theme_constant_override("separation", 14)
	add_child(bar)

	# 日期 + 时段进度（行动次数）
	var tbox := VBoxContainer.new()
	tbox.add_theme_constant_override("separation", 2)
	bar.add_child(tbox)
	tbox.add_child(UiKit.label(GameState.time_label(), 22, UiKit.C_GOLD, UiKit.SANS_BOLD))
	var left := GameState.days_left()
	tbox.add_child(UiKit.label("离出征还有 %d 天" % left if left > 0 else "明天清晨出征", 13, UiKit.C_DIM))
	bar.add_child(_slot_pips())
	bar.add_child(_vsep())

	# 疑云值
	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 3)
	dbox.tooltip_text = DialogueRules.doubt_desc(GameState.doubt)
	dbox.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.add_child(dbox)
	var dh := HBoxContainer.new()
	dh.add_child(UiKit.label("疑云值", 14, UiKit.C_DIM))
	var dv := UiKit.label("%d" % GameState.doubt, 15, UiKit.C_RED if GameState.doubt >= 60 else UiKit.C_TEXT, UiKit.SANS_BOLD)
	dh.add_child(dv)
	dbox.add_child(dh)
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(150, 8)
	pb.max_value = 100
	pb.value = GameState.doubt
	pb.show_percentage = false
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dbox.add_child(pb)
	bar.add_child(_vsep())

	# 讨伐队
	var p := EndingRules.check_party(GameState)
	var party := HBoxContainer.new()
	party.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party.add_theme_constant_override("separation", 6)
	party.add_child(UiKit.label("讨伐队", 14, UiKit.C_DIM))
	if p.party.size() == 0:
		party.add_child(UiKit.label("（无人）", 15, UiKit.C_DIM))
	for id in GameState.npcs:
		var n: NpcState = GameState.npcs[id]
		if n.is_joined():
			var fb := UiKit.face_badge(id, 30, UiKit.C_GREEN)
			fb.tooltip_text = n.display_name()
			fb.mouse_filter = Control.MOUSE_FILTER_PASS
			party.add_child(fb)
	bar.add_child(party)

	bar.add_child(UiKit.button("手记", func(): journal_requested.emit(), 16))
	bar.add_child(UiKit.button("休息", func(): _confirm_rest(), 16))
	bar.add_child(UiKit.button("菜单", func(): menu_requested.emit(), 16))


## 四个时段的进度点：已用 / 当前 / 未到
## 右上角“接下来”：具体的下一步 + 即将到来的事件
func _build_quest_panel() -> void:
	var lines := GoalSystem.quest_lines(GameState, 4)
	if lines.is_empty():
		return
	var panel := PanelContainer.new()
	var ps := UiKit.panel_style(UiKit.C_BG, UiKit.C_BORDER, 0.86)
	ps.content_margin_top = 10
	ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	panel.position = Vector2(892, 80)
	panel.custom_minimum_size = Vector2(370, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var t := UiKit.label("接下来", 16, UiKit.C_GOLD, UiKit.SANS_BOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 7)
	var fold := UiKit.button("收起", func(): pass, 12)
	fold.pressed.connect(func():
		body.visible = not body.visible
		fold.text = "展开" if not body.visible else "收起")
	head.add_child(fold)
	v.add_child(head)
	v.add_child(body)
	for q in lines:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon := {"event": "◷", "done": "★", "npc": "◆"}.get(q.kind, "·") as String
		var col := {"event": UiKit.C_BLUE, "done": UiKit.C_GREEN}.get(q.kind, UiKit.C_GOLD) as Color
		if q.has("id"):
			row.add_child(UiKit.face_badge(q.id, 30))
		else:
			var il := UiKit.label(icon, 18, col)
			il.custom_minimum_size = Vector2(32, 0)
			il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(il)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 1)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UiKit.wrap_label(q.text, 15, UiKit.C_TEXT, UiKit.SANS_MEDIUM))
		if str(q.get("sub", "")) != "":
			tv.add_child(UiKit.wrap_label(q.sub, 12, UiKit.C_DIM))
		if str(q.get("where", "")) != "":
			tv.add_child(UiKit.wrap_label(str(q.where), 12, UiKit.C_GOLD_DIM))
		row.add_child(tv)
		body.add_child(row)


## 回到地图时弹出积攒的提示（目标完成、获得线索……）
func _show_toasts() -> void:
	var items: Array = GameState.toasts.duplicate()
	GameState.toasts.clear()
	if items.is_empty():
		return
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.position = Vector2(340, 84)
	box.custom_minimum_size = Vector2(540, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	for i in items.size():
		var s := str(items[i])
		var p := PanelContainer.new()
		var st := UiKit.panel_style(Color("#1e1810"), UiKit.C_GOLD if (s.begins_with("★") or s.begins_with("➜")) else UiKit.C_BORDER, 0.94)
		st.content_margin_top = 8
		st.content_margin_bottom = 8
		p.add_theme_stylebox_override("panel", st)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col := UiKit.C_GOLD if (s.begins_with("★") or s.begins_with("◈") or s.begins_with("➜")) else UiKit.C_TEXT
		p.add_child(UiKit.wrap_label(s, 15, col, UiKit.SANS_MEDIUM))
		p.modulate.a = 0.0
		box.add_child(p)
		var tw := p.create_tween()
		tw.tween_interval(0.25 * i)
		tw.tween_property(p, "modulate:a", 1.0, 0.3)
		tw.tween_interval(5.0 + 0.6 * items.size())
		tw.tween_property(p, "modulate:a", 0.0, 0.6)
		tw.tween_callback(p.queue_free)


func _slot_pips() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in 4:
		var cur := i == GameState.slot
		var past := i < GameState.slot
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(3)
		s.set_border_width_all(1)
		s.border_color = UiKit.C_GOLD if cur else Color(UiKit.C_BORDER, 0.9)
		s.bg_color = Color(UiKit.C_GOLD, 0.25) if cur else (Color("#0d0a11", 0.6) if not past else Color("#3a3040", 0.6))
		s.content_margin_left = 6
		s.content_margin_right = 6
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", s)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col := UiKit.C_GOLD if cur else (Color("#6a6070") if past else UiKit.C_DIM)
		p.add_child(UiKit.label(GameState.SLOTS[i], 13, col, UiKit.SANS_BOLD if cur else UiKit.SANS))
		h.add_child(p)
	return h


func _vsep() -> Control:
	var c := ColorRect.new()
	c.color = Color(UiKit.C_BORDER, 0.7)
	c.custom_minimum_size = Vector2(1, 34)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


func _add_hotspot(loc_id: String, loc: Dictionary) -> void:
	var r: Array = loc.rect
	var rect := Rect2(r[0] * SCALE, r[1] * SCALE, r[2] * SCALE, r[3] * SCALE)
	var b := Button.new()
	b.position = rect.position
	b.size = rect.size
	b.flat = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 0.88, 0.55, 0.10)
	hover.border_color = Color(UiKit.C_GOLD, 0.9)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(14)
	hover.shadow_color = Color(UiKit.C_GOLD, 0.25)
	hover.shadow_size = 10
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): _open_location(loc_id))
	add_child(b)

	# 名牌：地点名（宋体）+ 在场人物头像
	var plate := PanelContainer.new()
	var ps := UiKit.panel_style(UiKit.C_BG, UiKit.C_BORDER, 0.82)
	ps.set_corner_radius_all(16)
	ps.shadow_size = 6
	ps.content_margin_left = 12
	ps.content_margin_right = 8
	ps.content_margin_top = 3
	ps.content_margin_bottom = 3
	plate.add_theme_stylebox_override("panel", ps)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 6)
	plate.add_child(ph)
	var nl := UiKit.serif_label(loc.name, 17, UiKit.C_GOLD, true)
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ph.add_child(nl)
	var present := GameState.npcs_at(loc_id)
	for id in present:
		ph.add_child(UiKit.face_badge(id, 30))
	if present.is_empty():
		var nobody := UiKit.label("无人", 13, UiKit.C_DIM)
		nobody.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ph.add_child(nobody)
	add_child(plate)
	# 放在热区底部居中（先按估算宽度定位，尺寸确定后再修正）
	var center_x := rect.position.x + rect.size.x / 2.0
	var y := rect.end.y - 18
	plate.position = Vector2(center_x - 80, y)
	plate.resized.connect(func(): plate.position = Vector2(clampf(center_x - plate.size.x / 2.0, 8, 1272 - plate.size.x), minf(y, 650)))


# ---------------------------------------------------------------- 地点场景

func _open_location(loc_id: String) -> void:
	if _popup:
		_popup.queue_free()
	var loc: Dictionary = GameState.locations[loc_id]
	_popup = Control.new()
	_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_popup)

	var night := GameState.slot == 3
	var bg_tex := UiKit.location_bg(loc_id, night)
	var base := ColorRect.new()
	base.color = UiKit.C_BG
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(base)
	if bg_tex:
		var tint: Color = Color.WHITE if (night and UiKit.has_night_art(loc_id)) else TINTS[clampi(GameState.slot, 0, 3)]
		_popup.add_child(UiKit.cover_rect(bg_tex, tint))
	_popup.add_child(UiKit.gradient_rect("right", 0.92, UiKit.C_BG, 0.45))
	_popup.add_child(UiKit.gradient_rect("bottom", 0.7, Color.BLACK, 0.6))
	var catcher := Control.new()  # 点击空白处返回地图
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT: _close_popup())
	_popup.add_child(catcher)

	# 在场人物：站在场景里，点击即可交谈
	var present := GameState.npcs_at(loc_id)
	var n_count := present.size()
	var ph := 520.0
	var pw := ph / 1.5
	var spread := 250.0 if n_count >= 3 else 300.0
	var cx0 := 430.0 - spread * (n_count - 1) / 2.0
	for i in n_count:
		var id: String = present[i]
		_popup.add_child(_standing_npc(id, loc_id, Vector2(cx0 + spread * i - pw / 2.0, 720 - ph), Vector2(pw, ph)))

	# 右侧信息面板
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.C_PANEL, UiKit.C_BORDER, 0.88))
	panel.position = Vector2(850, 60)
	panel.size = Vector2(400, 620)
	panel.custom_minimum_size = panel.size
	_popup.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(UiKit.label(GameState.time_label(), 14, UiKit.C_DIM, UiKit.SANS_BOLD))
	v.add_child(UiKit.title_label(loc.name, 34))
	v.add_child(UiKit.wrap_label(loc.desc, 17, Color("#d8cdb9"), UiKit.SERIF))
	v.add_child(HSeparator.new())
	if present.is_empty():
		v.add_child(UiKit.wrap_label("这个时段这里没有你要找的人。", 16, UiKit.C_DIM))
	for id in present:
		v.add_child(_npc_row(id, loc_id))
	var regulars := PackedStringArray()
	for id in GameState.npcs:
		if present.has(id):
			continue
		var n: NpcState = GameState.npcs[id]
		var slots := PackedStringArray()
		for i in 4:
			if str(n.def.get("schedule", {}).get(GameState.SLOT_KEYS[i], "")) == loc_id:
				slots.append(GameState.SLOTS[i])
		if not slots.is_empty():
			regulars.append("%s（%s）" % [n.display_name(), "/".join(slots)])
	if not regulars.is_empty():
		v.add_child(UiKit.wrap_label("其他时段常来这里：" + "、".join(regulars), 13, UiKit.C_DIM))
	var acts := location_actions(loc_id)
	if acts.size() > 0:
		v.add_child(HSeparator.new())
	for a in acts:
		var ab := UiKit.button(a.label, func(): location_action.emit(a.id, loc_id), 15)
		ab.tooltip_text = a.get("tip", "")
		ab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(ab)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	v.add_child(UiKit.wrap_label("点击人物或「交谈」开始对话。和人说上一句话就会消耗这个时段。", 13, UiKit.C_DIM))
	v.add_child(UiKit.button("◀  返回地图", _close_popup))


func _standing_npc(id: String, loc_id: String, pos: Vector2, sz: Vector2) -> Control:
	var b := TextureButton.new()
	b.texture_normal = UiKit.portrait(id)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.position = pos
	b.size = sz
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "和%s交谈" % GameState.npcs[id].display_name()
	b.self_modulate = Color(0.92, 0.9, 0.88)
	b.mouse_entered.connect(func(): b.self_modulate = Color(1.12, 1.08, 1.0))
	b.mouse_exited.connect(func(): b.self_modulate = Color(0.92, 0.9, 0.88))
	b.pressed.connect(func(): talk_requested.emit(id, loc_id))
	return b


func _npc_row(id: String, loc_id: String) -> Control:
	var n: NpcState = GameState.npcs[id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UiKit.face_badge(id, 56, UiKit.stance_color(n.stance)))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.serif_label(n.display_name(), 20, UiKit.C_GOLD, true))
	var tags := HFlowContainer.new()
	tags.add_theme_constant_override("h_separation", 4)
	tags.add_theme_constant_override("v_separation", 4)
	tags.add_child(UiKit.chip(n.stance, UiKit.stance_color(n.stance), 13))
	if n.is_joined():
		tags.add_child(UiKit.chip("已加入讨伐队", UiKit.C_GREEN, 13))
	elif GoalSystem.can_join(n):
		tags.add_child(UiKit.chip("可以邀请加入", UiKit.C_GOLD, 13))
	info.add_child(tags)
	var d: Dictionary = n.def.get("dossier", {})
	var g := GoalSystem.next_goal(n)
	var line := ""
	if not bool(n.flags.get("met", false)):
		line = "传闻：" + str(d.get("rumor", ""))
	elif not g.is_empty() and not n.is_joined():
		line = "心结：" + str(g.title)
	elif d.has("wants"):
		line = "想要：" + str(d.wants)
	if line != "":
		var dl := UiKit.wrap_label(line, 13, UiKit.C_DIM)
		dl.custom_minimum_size = Vector2(200, 0)
		info.add_child(dl)
	row.add_child(info)
	var b := UiKit.primary_button("交谈", func(): talk_requested.emit(id, loc_id), 16)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return row


static func location_actions(loc_id: String) -> Array:
	var res: Array = []
	if loc_id == "tavern" and GameState.slot >= 2:
		res.append({"id": "rumor", "label": "在酒馆里打听流言（消耗这个时段）", "tip": "看看王都的人都在怎么议论你。"})
	if loc_id == "temple" and GameState.slot == 3 and not bool(GameState.flags.get("investigated_altar", false)):
		res.append({"id": "investigate", "label": "潜入正殿，调查圣剑的剑座（消耗这个时段，有风险）", "tip": "如果有懂行的人帮你望风开锁，会安全得多。"})
	return res


func has_popup() -> bool:
	return _popup != null and is_instance_valid(_popup)


func _close_popup() -> void:
	if _popup:
		_popup.queue_free()
		_popup = null


func _confirm_rest() -> void:
	if _popup:
		_popup.queue_free()
	_popup = Control.new()
	_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_popup)
	_popup.add_child(UiKit.dim_layer(0.55))
	var panel := UiKit.centered_panel(_popup, Vector2(480, 190))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	v.add_child(UiKit.label("休息", 22, UiKit.C_GOLD, UiKit.SANS_BOLD))
	v.add_child(UiKit.wrap_label("在住处休息，跳过「%s」这个时段？" % GameState.slot_name(), 17))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_child(UiKit.button("取消", _close_popup))
	h.add_child(UiKit.primary_button("休息", func(): rest_requested.emit()))
	v.add_child(h)
