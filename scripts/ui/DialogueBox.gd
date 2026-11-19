class_name DialogueBox
extends Control
## 对话界面（视觉小说式）：地点场景 + 左侧大立绘 / 关系 / 心结 + 右侧台词记录 / 推荐说法 / 出示线索 / 邀请加入 / 自由输入。
## closed(turns_used) —— 玩家成功说出的句数。0 表示只听了开场白就离开（不消耗时段）。

signal closed(turns_used: int)
signal open_settings

var npc: NpcState
var location_name: String = ""
var scene_id: String = ""        # 背景：地点 id / "map" / "cg:<id>"，空 = 纯色
var turn: int = 0                # 玩家已经说了几句
var exchanges: int = 0           # 成功的回合数（含开场白）
var busy := false
var ended := false
var last_failed_line := ""
var last_failed_special := {}
var debug_visible := true

var _portrait: TextureRect
var _name_label: Label
var _tag_box: HFlowContainer
var _bars_box: HBoxContainer
var _goal_box: VBoxContainer
var _stats_panel: PanelContainer
var _stats_label: RichTextLabel
var _log: RichTextLabel
var _thinking: Label
var _sugg_title: Label
var _sugg_box: VBoxContainer
var _present_btn: Button
var _invite_btn: Button
var _input: LineEdit
var _send_btn: Button
var _turn_label: Label
var _leave_btn: Button
var _retry_box: HBoxContainer
var _think_t := 0.0
var _start := {}                 # 谈话开始时的快照（用于小结）
var _session_notes: Array = []   # 本次谈话里的目标 / 线索提示
var _summary: Control


func setup(n: NpcState, loc_name: String, show_debug: bool, scene: String = "") -> void:
	npc = n
	location_name = loc_name
	debug_visible = show_debug
	scene_id = scene


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_start = {"trust": npc.trust, "suspicion": npc.suspicion, "stance": npc.stance,
		"claims": npc.player_claims.size(), "joined": npc.is_joined()}
	# 背景
	var base := ColorRect.new()
	base.color = UiKit.C_BG
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(base)
	var night := GameState.slot == 3
	var tex := UiKit.scene_tex(scene_id, night)
	if tex:
		var tint: Color = UiKit.SLOT_TINTS[clampi(GameState.slot, 0, 3)]
		if night and UiKit.has_night_art(scene_id):
			tint = Color.WHITE
		add_child(UiKit.cover_rect(tex, tint * Color(0.75, 0.75, 0.75)))
	add_child(UiKit.vignette(0.6))
	add_child(UiKit.gradient_rect("right", 0.9, UiKit.C_BG, 0.3))

	# 左侧：大立绘
	_portrait = TextureRect.new()
	_portrait.texture = UiKit.portrait(npc.id)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.position = Vector2(10, 30)
	_portrait.size = Vector2(460, 690)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	var foot := UiKit.gradient_rect("bottom", 0.97, UiKit.C_BG, 0.0)
	foot.set_anchors_preset(Control.PRESET_TOP_LEFT)
	foot.position = Vector2(0, 380)
	foot.size = Vector2(500, 340)
	add_child(foot)

	# 姓名 / 关系 / 心结（贴底，向上生长）
	var nv := VBoxContainer.new()
	nv.anchor_top = 1
	nv.anchor_bottom = 1
	nv.offset_left = 30
	nv.offset_right = 470
	nv.offset_top = -20
	nv.offset_bottom = -20
	nv.grow_vertical = Control.GROW_DIRECTION_BEGIN
	nv.add_theme_constant_override("separation", 5)
	add_child(nv)
	_name_label = UiKit.title_label(npc.display_name(), 34)
	nv.add_child(_name_label)
	nv.add_child(UiKit.serif_label(str(npc.def.title), 15, Color("#cfc3ae")))
	_tag_box = HFlowContainer.new()
	_tag_box.add_theme_constant_override("h_separation", 6)
	_tag_box.add_theme_constant_override("v_separation", 4)
	nv.add_child(_tag_box)
	_bars_box = HBoxContainer.new()
	_bars_box.add_theme_constant_override("separation", 16)
	nv.add_child(_bars_box)
	_goal_box = VBoxContainer.new()
	_goal_box.add_theme_constant_override("separation", 2)
	nv.add_child(_goal_box)

	# 调试数值（F1）
	_stats_panel = PanelContainer.new()
	_stats_panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color.BLACK, Color("#3e3346"), 0.6))
	_stats_panel.position = Vector2(20, 20)
	_stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stats_panel)
	_stats_label = UiKit.rich(false, 13)
	_stats_label.fit_content = true
	_stats_label.scroll_active = false
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.custom_minimum_size = Vector2(420, 0)
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_panel.add_child(_stats_label)

	# 右侧：对话面板
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.C_PANEL, UiKit.C_BORDER, 0.9))
	right.position = Vector2(490, 20)
	right.size = Vector2(770, 680)
	right.custom_minimum_size = right.size
	add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	right.add_child(rv)

	var head := HBoxContainer.new()
	var loc_l := UiKit.serif_label(location_name, 16, UiKit.C_GOLD_DIM, true)
	loc_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loc_l.clip_text = true
	head.add_child(loc_l)
	_turn_label = UiKit.label("", 14, UiKit.C_DIM, UiKit.SANS_BOLD)
	_turn_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_turn_label)
	var hist_btn := UiKit.button("对话记录", func(): add_child(InfoPanels.history(npc)), 15)
	hist_btn.tooltip_text = "查看和%s说过的所有话" % npc.display_name()
	head.add_child(hist_btn)
	_leave_btn = UiKit.button("结束对话", _on_leave, 15)
	head.add_child(_leave_btn)
	rv.add_child(head)
	rv.add_child(HSeparator.new())

	_log = UiKit.rich(true, 19)
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.selection_enabled = true
	_log.add_theme_constant_override("line_separation", 7)
	_log.add_theme_constant_override("paragraph_separation", 12)
	_log.add_theme_color_override("selection_color", Color(UiKit.C_GOLD, 0.25))
	rv.add_child(_log)

	_thinking = UiKit.label("", 15, UiKit.C_DIM)
	_thinking.custom_minimum_size = Vector2(0, 20)
	rv.add_child(_thinking)
	_retry_box = HBoxContainer.new()
	_retry_box.visible = false
	_retry_box.add_child(UiKit.primary_button("重试", _on_retry, 15))
	_retry_box.add_child(UiKit.button("连接设置", func(): open_settings.emit(), 15))
	rv.add_child(_retry_box)

	# 推荐说法 + 行动按钮
	var srow := HBoxContainer.new()
	_sugg_title = UiKit.label("推荐说法　·　点击填入，可修改后发送；也可按 1 / 2 / 3", 13, UiKit.C_DIM)
	_sugg_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sugg_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	srow.add_child(_sugg_title)
	_present_btn = UiKit.button("出示线索", _open_card_picker, 14)
	_present_btn.tooltip_text = "把手里的线索、证据或物品拿给对方看。输入框里写的话会一起说出去。"
	srow.add_child(_present_btn)
	_invite_btn = UiKit.button("邀请加入讨伐队", _on_invite, 14)
	_invite_btn.visible = not npc.is_antagonist()
	srow.add_child(_invite_btn)
	rv.add_child(srow)
	_sugg_box = VBoxContainer.new()
	_sugg_box.add_theme_constant_override("separation", 5)
	rv.add_child(_sugg_box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UiKit.face_badge("hero", 42, UiKit.C_BLUE))
	_input = LineEdit.new()
	_input.placeholder_text = "说出你（勇者）想说的话……　最多 %d 字，回车发送" % DialogueRules.MAX_INPUT_CHARS
	_input.max_length = DialogueRules.MAX_INPUT_CHARS
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size = Vector2(0, 44)
	_input.text_submitted.connect(func(_t): _on_send())
	row.add_child(_input)
	_send_btn = UiKit.primary_button("发送", _on_send, 17)
	_send_btn.custom_minimum_size = Vector2(84, 44)
	row.add_child(_send_btn)
	rv.add_child(row)

	_refresh_side()
	_update_turn_label()
	_show_recap()
	_request(0, "")


## 打开对话时，先灰色显示上一次谈话的最后几句，帮玩家接上话头。
func _show_recap() -> void:
	if npc.transcript.is_empty():
		return
	var last: Dictionary = npc.transcript[-1]
	var session: Array = []
	for i in range(npc.transcript.size() - 1, -1, -1):
		var e: Dictionary = npc.transcript[i]
		if e.get("day") != last.get("day") or e.get("slot") != last.get("slot"):
			break
		session.push_front(e)
	_log.append_text(InfoPanels.transcript_bbcode(npc, session.slice(maxi(0, session.size() - 4)), true))
	_append(UiKit.bb_sans("—— 现在 ——", 13, UiKit.C_GOLD_DIM))


func _process(delta: float) -> void:
	if busy:
		_think_t += delta
		_thinking.text = "%s 正在思考%s" % [npc.display_name(), "·".repeat(1 + int(_think_t * 3) % 3)]


func set_debug_visible(v: bool) -> void:
	debug_visible = v
	_refresh_side()


# ---------------------------------------------------------------- 左侧：关系 / 心结

static func meter_names(n: NpcState) -> Array:
	return n.def.get("meters", ["信任", "怀疑"])


static func _bar(label: String, value: int, col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(UiKit.label(label, 13, UiKit.C_DIM))
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(130, 8)
	pb.max_value = 100
	pb.value = value
	pb.show_percentage = false
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("fill", fill)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(pb)
	return h


func _refresh_side(r: Dictionary = {}) -> void:
	for c in _tag_box.get_children():
		c.queue_free()
	_tag_box.add_child(UiKit.chip("态度：" + npc.stance, UiKit.stance_color(npc.stance), 13))
	for t in UiKit.npc_tags(npc):
		_tag_box.add_child(UiKit.chip(t[0], t[1], 13))
	for c in _bars_box.get_children():
		c.queue_free()
	var mn := meter_names(npc)
	_bars_box.add_child(_bar(mn[0], npc.trust, Color("#c9a65a")))
	_bars_box.add_child(_bar(mn[1], npc.suspicion, UiKit.C_RED))
	for c in _goal_box.get_children():
		c.queue_free()
	var gl := GoalSystem.visible_goals(npc)
	if not gl.is_empty():
		_goal_box.add_child(UiKit.label("%s的心结" % npc.display_name(), 13, UiKit.C_GOLD_DIM, UiKit.SANS_BOLD))
		for g in gl:
			var done := GoalSystem.is_done(npc, g.id)
			var l := UiKit.label(("√ " if done else "○ ") + str(g.title), 14, UiKit.C_GREEN if done else UiKit.C_TEXT)
			l.tooltip_text = "" if done else str(g.hint)
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			_goal_box.add_child(l)
			if not done and g == GoalSystem.next_goal(npc):
				var hl := UiKit.wrap_label("　" + str(g.hint), 13, UiKit.C_DIM)
				hl.custom_minimum_size = Vector2(430, 0)
				_goal_box.add_child(hl)
		if npc.is_joined():
			_goal_box.add_child(UiKit.label("★ 已加入讨伐队", 14, UiKit.C_GREEN, UiKit.SANS_BOLD))
		elif GoalSystem.can_join(npc):
			_goal_box.add_child(UiKit.label("➜ 可以邀请%s加入讨伐队了" % GoalSystem.pronoun(npc), 14, UiKit.C_GOLD, UiKit.SANS_BOLD))
	if _invite_btn:
		_invite_btn.visible = not npc.is_antagonist() and not npc.is_joined()
		_invite_btn.add_theme_color_override("font_color", UiKit.C_GOLD if GoalSystem.can_join(npc) else UiKit.C_TEXT)
	if _present_btn:
		_present_btn.text = "出示线索（%d）" % GameState.cards.size()

	_stats_panel.visible = debug_visible
	if not debug_visible:
		return
	var b: Dictionary = r.get("before", {})
	_stats_label.text = "[color=#a59b8b]调试数值（F1）[/color]\n信任 %s　怀疑 %s　好感 %s" % [
		_stat(npc.trust, b.get("trust", npc.trust)),
		_stat(npc.suspicion, b.get("suspicion", npc.suspicion)),
		_stat(npc.affinity, b.get("affinity", npc.affinity))]
	var u := str(r.get("understanding", ""))
	if u != "":
		_stats_label.text += "\n[color=#a59b8b]模型的理解：[/color]" + _esc(u)


func _stat(v: int, old: int) -> String:
	var d := v - old
	if d == 0:
		return "%d" % v
	var col := UiKit.hex(UiKit.C_GREEN) if d > 0 else UiKit.hex(UiKit.C_RED)
	return "%d [color=%s](%+d)[/color]" % [v, col, d]


func _update_turn_label() -> void:
	_turn_label.text = "第 %d / %d 句" % [turn, DialogueRules.MAX_TURNS]


# ---------------------------------------------------------------- 记录

func _append(text: String) -> void:
	if _log.get_parsed_text() != "":
		_log.append_text("\n")
	_log.append_text(text)


func _system(text: String, col: Color = UiKit.C_DIM) -> void:
	_append(UiKit.bb_sans(text, 15, col))


static func arrows(d: int) -> String:
	var a := absi(d)
	var n := 1 if a <= 5 else (2 if a <= 10 else 3)
	return ("↑" if d > 0 else "↓").repeat(n)


## 每轮的可见反馈：信任 / 怀疑的变化方向 + 对方的一句感受
func _feedback(r: Dictionary) -> void:
	var b: Dictionary = r.get("before", {})
	var dt: int = npc.trust - int(b.get("trust", npc.trust))
	var ds: int = npc.suspicion - int(b.get("suspicion", npc.suspicion))
	var parts := PackedStringArray()
	var mn := meter_names(npc)
	if dt != 0:
		parts.append("[color=%s]%s%s[/color]" % [UiKit.hex(UiKit.C_GREEN if dt > 0 else UiKit.C_RED), mn[0], arrows(dt)])
	if ds != 0:
		parts.append("[color=%s]%s%s[/color]" % [UiKit.hex(UiKit.C_RED if ds > 0 else UiKit.C_GREEN), mn[1], arrows(ds)])
	var imp := str(r.get("impression", ""))
	if parts.is_empty() and imp == "":
		return
	var s := "◇ " + "　".join(parts)
	if imp != "":
		s += ("　" if not parts.is_empty() else "") + "[color=#cfc3ae]「%s」[/color]" % _esc(imp)
	_append(UiKit.bb_sans(s, 14, UiKit.C_DIM))


# ---------------------------------------------------------------- 发言

func _on_send() -> void:
	if busy or ended:
		return
	var line := _input.text.strip_edges()
	if line.is_empty():
		return
	line = line.left(DialogueRules.MAX_INPUT_CHARS)
	_request(turn + 1, line)


func _on_invite() -> void:
	if busy or ended:
		return
	var extra := _input.text.strip_edges()
	var line := extra if extra != "" else "我想请你加入讨伐队，和我一起出征。"
	_request(turn + 1, line.left(DialogueRules.MAX_INPUT_CHARS), {"type": "invite"})


func _present(card_id: String) -> void:
	if busy or ended:
		return
	var extra := _input.text.strip_edges()
	var line := "（拿出「%s」）" % GoalSystem.card_name(card_id)
	if extra != "":
		line += extra
	_request(turn + 1, line.left(DialogueRules.MAX_INPUT_CHARS + 20), {"type": "present", "card": card_id})


func _open_card_picker() -> void:
	if busy or ended:
		return
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(UiKit.dim_layer(0.6))
	add_child(root)
	var panel := UiKit.centered_panel(root, Vector2(760, 560))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var t := UiKit.label("出示给%s看" % npc.display_name(), 22, UiKit.C_GOLD, UiKit.SANS_BOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UiKit.button("取消", func(): root.queue_free(), 15))
	v.add_child(head)
	v.add_child(UiKit.wrap_label("出示会占用一句话。输入框里写的话会一起说出去。不同的人看到同一样东西，反应可能完全不同。", 13, UiKit.C_DIM))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	sc.add_child(list)
	if GameState.cards.is_empty():
		list.add_child(UiKit.wrap_label("你手里还没有任何线索。和人深谈、参加事件、夜里调查都可能得到线索。", 15, UiKit.C_DIM))
	var shown: Array = npc.flags.get("presented", [])
	for id in GameState.cards:
		var cb := func():
			root.queue_free()
			_present(id)
		list.add_child(card_row(id, cb, "出示", shown.has(id)))


## 一张线索卡的显示行（手记的“线索”页也用）
static func card_row(id: String, cb: Callable = Callable(), btn_text: String = "", dim_btn: bool = false) -> Control:
	var c := GoalSystem.clue(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	var nh := HBoxContainer.new()
	nh.add_child(UiKit.label(str(c.get("name", id)), 17, UiKit.C_GOLD, UiKit.SANS_BOLD))
	var type_col := {"证据": UiKit.C_RED, "物品": UiKit.C_BLUE, "情报": UiKit.C_GREEN}.get(str(c.get("type", "")), UiKit.C_PURPLE) as Color
	nh.add_child(UiKit.chip(str(c.get("type", "线索")), type_col, 12))
	info.add_child(nh)
	var d := UiKit.wrap_label(str(c.get("desc", "")), 14, Color("#d8cdb9"))
	info.add_child(d)
	info.add_child(UiKit.label("来源：" + str(c.get("source", "")), 12, UiKit.C_DIM))
	row.add_child(info)
	if cb.is_valid():
		var b := UiKit.primary_button(btn_text, cb, 15) if not dim_btn else UiKit.button(btn_text + "（已出示过）", cb, 14)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	return row


func _on_retry() -> void:
	if busy:
		return
	_retry_box.visible = false
	if exchanges == 0:
		_request(0, "")
	else:
		_request(turn + 1, last_failed_line, last_failed_special)


func _request(t: int, line: String, special: Dictionary = {}) -> void:
	busy = true
	_think_t = 0.0
	_set_input_enabled(false)
	_retry_box.visible = false
	if t > 0:
		_append("[color=%s][b]你[/b][/color]　[color=#c9d6e8]%s[/color]" % [UiKit.hex(UiKit.C_BLUE), _esc(line)])
	var res: Dictionary = await NpcBrain.run_turn(npc, t, line, location_name, special)
	if not is_inside_tree():
		return
	busy = false
	_thinking.text = ""
	if not res.ok:
		last_failed_line = line
		last_failed_special = special
		var hint := "（Key 或账户的问题，请检查连接设置）" if LlmClient.error_is_key_problem(res.error_kind) else ""
		_system("× %s%s　这句话没有生效，状态没有改变。" % [_esc(res.message), hint], UiKit.C_RED)
		if t > 0 and special.is_empty():
			_input.text = line
		_retry_box.visible = true
		_set_input_enabled(true)
		return
	if t > 0:
		turn = t
		_input.text = ""
	exchanges += 1
	var r: Dictionary = res.result
	_portrait.texture = UiKit.portrait(npc.id, r.emotion)
	_append("[color=%s][b]%s[/b][/color]　%s" % [UiKit.hex(UiKit.C_GOLD), npc.display_name(), _esc(r.reply)])
	if t > 0:
		_feedback(r)
	for note in res.notes:
		var s := str(note)
		var col := UiKit.C_PURPLE
		if s.begins_with("★") or s.begins_with("◈") or s.begins_with("➜"):
			col = UiKit.C_GOLD
			_session_notes.append(s)
		elif s.begins_with("⚠") or s.begins_with("×"):
			col = UiKit.C_RED
		_system(_esc(s), col)
	_refresh_side(r)
	_update_turn_label()
	_show_suggestions(r.suggested_replies)
	if r.action == "end_conversation" or turn >= DialogueRules.MAX_TURNS:
		_end("（%s 结束了这次谈话。）" % npc.display_name())
	else:
		_set_input_enabled(true)
		_input.grab_focus()


func _end(msg: String) -> void:
	ended = true
	_system(msg)
	_set_input_enabled(false)
	for c in _sugg_box.get_children():
		c.queue_free()
	_sugg_title.visible = false
	_leave_btn.text = "离开"
	_leave_btn.add_theme_stylebox_override("normal", UiKit.btn_style(Color("#3a2c1c", 0.95), UiKit.C_GOLD))
	_leave_btn.grab_focus()


func _show_suggestions(list: Array) -> void:
	for c in _sugg_box.get_children():
		c.queue_free()
	_sugg_title.visible = true
	for i in list.size():
		var s: Dictionary = list[i]
		var col: Color = UiKit.TACTIC_COLORS.get(s.tactic, UiKit.C_TEXT)
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%d　〔%s〕　%s" % [i + 1, s.tactic, s.text]
		b.add_theme_font_override("font", UiKit.font(UiKit.SANS))
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", col.lerp(UiKit.C_TEXT, 0.25))
		b.add_theme_color_override("font_hover_color", col.lightened(0.25))
		var st := UiKit.btn_style(Color("#0f0c13", 0.7), Color(col, 0.35))
		st.border_width_left = 3
		var sth := st.duplicate()
		sth.bg_color = Color(col, 0.12)
		sth.border_color = Color(col, 0.85)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", sth)
		b.add_theme_stylebox_override("pressed", sth)
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.tooltip_text = s.text
		var txt: String = s.text
		b.pressed.connect(func():
			_input.text = txt
			_input.caret_column = txt.length()
			_input.grab_focus())
		_sugg_box.add_child(b)


func _set_input_enabled(v: bool) -> void:
	_input.editable = v and not ended
	_send_btn.disabled = not v or ended
	_present_btn.disabled = not v or ended
	_invite_btn.disabled = not v or ended
	for c in _sugg_box.get_children():
		if c is Button:
			c.disabled = not v or ended


# ---------------------------------------------------------------- 离开 + 小结

func _on_leave() -> void:
	if busy:
		return
	if turn == 0 or _summary != null:
		closed.emit(turn)
		return
	_show_summary()


static func change_word(d: int) -> String:
	var a := absi(d)
	if a == 0:
		return "没有变化"
	var deg := "略微" if a <= 5 else ("明显" if a <= 14 else "大幅")
	return deg + ("上升" if d > 0 else "下降")


func _show_summary() -> void:
	_summary = Control.new()
	_summary.set_anchors_preset(Control.PRESET_FULL_RECT)
	_summary.add_child(UiKit.dim_layer(0.6))
	add_child(_summary)
	var panel := UiKit.centered_panel(_summary, Vector2(560, 440))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiKit.face_badge(npc.id, 48, UiKit.stance_color(npc.stance)))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.add_child(UiKit.label("谈话小结", 13, UiKit.C_DIM))
	tv.add_child(UiKit.title_label(npc.display_name(), 24))
	head.add_child(tv)
	v.add_child(head)
	v.add_child(HSeparator.new())
	var r := UiKit.rich(false, 16)
	r.fit_content = true
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mn := meter_names(npc)
	var lines := PackedStringArray()
	var dt: int = npc.trust - int(_start.trust)
	var ds: int = npc.suspicion - int(_start.suspicion)
	lines.append("%s：[color=%s]%s[/color]" % [mn[0], UiKit.hex(UiKit.C_GREEN if dt > 0 else (UiKit.C_RED if dt < 0 else UiKit.C_DIM)), change_word(dt)])
	lines.append("%s：[color=%s]%s[/color]" % [mn[1], UiKit.hex(UiKit.C_RED if ds > 0 else (UiKit.C_GREEN if ds < 0 else UiKit.C_DIM)), change_word(ds)])
	if npc.stance != _start.stance:
		lines.append("态度：%s → %s" % [UiKit.stance_bbcode(_start.stance), UiKit.stance_bbcode(npc.stance)])
	else:
		lines.append("态度：%s" % UiKit.stance_bbcode(npc.stance))
	var new_claims: int = npc.player_claims.size() - int(_start.claims)
	if new_claims > 0:
		var who := "%s记下了你说的 %d 句关于神力 / 仪式 / 计划的话" % [npc.display_name(), new_claims]
		if not (npc.def.get("gossip_to", []) as Array).is_empty():
			who += "，可能会传给别人"
		lines.append("[color=%s]%s。[/color]" % [UiKit.hex(UiKit.C_DIM), who])
	if not _session_notes.is_empty():
		lines.append("")
		for s in _session_notes:
			lines.append("[color=%s]%s[/color]" % [UiKit.hex(UiKit.C_GOLD), _esc(s)])
	var ng := GoalSystem.next_goal(npc)
	if not npc.is_antagonist() and not npc.is_joined():
		lines.append("")
		if GoalSystem.can_join(npc):
			lines.append("[color=%s]下一步：邀请%s加入讨伐队。[/color]" % [UiKit.hex(UiKit.C_GOLD), GoalSystem.pronoun(npc)])
		elif not ng.is_empty():
			lines.append("下一步：%s\n[color=%s]%s[/color]" % [ng.title, UiKit.hex(UiKit.C_DIM), ng.hint])
	r.text = "\n".join(lines)
	v.add_child(r)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	var b := UiKit.primary_button("离开", func(): closed.emit(turn), 17)
	h.add_child(b)
	v.add_child(h)
	b.grab_focus.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
	if busy or ended or not (event is InputEventKey) or not event.pressed:
		return
	if _input.has_focus() and _input.text != "":
		return
	var k: int = event.keycode
	if k >= KEY_1 and k <= KEY_3:
		var idx := k - KEY_1
		var kids := _sugg_box.get_children()
		if idx < kids.size():
			(kids[idx] as Button).pressed.emit()
			get_viewport().set_input_as_handled()


static func _esc(s: String) -> String:
	return s.replace("[", "［").replace("]", "］")
