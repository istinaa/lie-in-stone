extends Control
## 流程控制：标题 → 开场 → 白天（地图/对话/事件）→ 夜间结算 → … → 第 8 天出征 → 结局。

var screen: Control
var overlay: Control
var show_debug := false   # F1 打开；自动测试和截图时默认打开
var _debug_layer: CanvasLayer
var _debug_label: RichTextLabel


func _ready() -> void:
	theme = UiKit.make_theme()
	get_tree().root.theme = theme  # 让 CanvasLayer 里的控件也用同一套主题
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 50
	add_child(_debug_layer)
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", UiKit.panel_style(Color.BLACK, Color("#4a4258"), 0.75))
	dp.position = Vector2(20, 440)
	dp.custom_minimum_size = Vector2(340, 0)
	dp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_debug_layer.add_child(dp)
	_debug_label = UiKit.rich(false, 13)
	_debug_label.fit_content = true
	_debug_label.custom_minimum_size = Vector2(320, 0)
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dp.add_child(_debug_label)
	_debug_layer.visible = false

	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for a in args:
		if a.begins_with("--autotest") or a.begins_with("--shots"):
			show_debug = true
			var t = load("res://scripts/dev/Autotest.gd").new()
			add_child(t)
			t.run(self, args)
			return
	show_title()


func _process(_d: float) -> void:
	_update_debug_visibility()
	if _debug_layer.visible:
		_debug_label.text = InfoPanels.debug(GameState)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		show_debug = not show_debug
		_update_debug_visibility()
		if overlay is DialogueBox:
			overlay.set_debug_visible(show_debug)


func _update_debug_visibility() -> void:
	_debug_layer.visible = show_debug and screen is TownView and overlay == null 		and not (screen as TownView).has_popup()


# ------------------------------------------------------------------ 屏幕管理

func _set_screen(c: Control) -> void:
	_close_overlay()
	if screen:
		screen.queue_free()
	screen = c
	add_child(c)
	move_child(c, 0)
	_update_debug_visibility()


func _set_overlay(c: Control) -> void:
	_close_overlay()
	overlay = c
	add_child(c)
	_update_debug_visibility()


func _close_overlay() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null
	_update_debug_visibility()


func _story(pages: Array, choices: Array = []) -> String:
	var s := StoryScreen.new()
	s.setup(pages, choices)
	_set_screen(s)
	var id: String = await s.finished
	return id


func _talk(npc_id: String, loc_name: String, scene: String = "") -> int:
	var n: NpcState = GameState.npcs[npc_id]
	var d := DialogueBox.new()
	d.setup(n, loc_name, show_debug, scene)
	d.open_settings.connect(_open_settings_over_dialogue)
	if screen == null or not (screen is TownView):
		var bg := ColorRect.new()
		bg.color = UiKit.C_BG
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		_set_screen(bg)
	_set_overlay(d)
	var used: int = await d.closed
	_close_overlay()
	if used > 0:
		GameState.log_journal("和%s谈了谈（%s）" % [n.display_name(), n.stance])
	if used >= 2:
		n.flags.sessions = int(n.flags.get("sessions", 0)) + 1
		GameState.check_goals()
	return used


func _open_settings_over_dialogue() -> void:
	var a := ApiSetup.new()
	add_child(a)
	await a.done
	a.queue_free()


# ------------------------------------------------------------------ 标题

func show_title() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.color = UiKit.C_BG
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(base)
	var art := UiKit.cg("ritual")
	root.add_child(UiKit.cover_rect(art if art else UiKit.town_map(), Color(0.85, 0.82, 0.8)))
	root.add_child(UiKit.gradient_rect("left", 0.96, UiKit.C_BG, 0.3))
	root.add_child(UiKit.vignette(0.55))

	var v := VBoxContainer.new()
	v.position = Vector2(96, 96)
	v.custom_minimum_size = Vector2(400, 0)
	v.add_theme_constant_override("separation", 10)
	root.add_child(v)
	var t := UiKit.label("圣剑之谎", 96, UiKit.C_GOLD, UiKit.SERIF_BLACK)
	t.add_theme_color_override("font_outline_color", Color("#2a1a08"))
	t.add_theme_constant_override("outline_size", 6)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	t.add_theme_constant_override("shadow_offset_y", 5)
	t.add_theme_constant_override("shadow_outline_size", 12)
	v.add_child(t)
	var en := UiKit.label("L I E   I N   S T O N E", 20, UiKit.C_GOLD, UiKit.SERIF_BOLD)
	en.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	en.add_theme_constant_override("shadow_outline_size", 6)
	v.add_child(en)
	var sub := UiKit.serif_label("七天。一把不会发光的剑。只靠说话。", 21, Color("#e8dcc4"))
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	sub.add_theme_constant_override("shadow_outline_size", 6)
	v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 40)
	v.add_child(gap)
	v.add_child(UiKit.primary_button("新的游戏", _on_new_game, 20))
	var saves := GameState.list_saves()
	if saves.size() > 0:
		v.add_child(UiKit.button("继续（第 %d 天早晨）" % saves[-1], func(): _load_and_play(saves[-1]), 19))
	if saves.size() > 1:
		var h := HFlowContainer.new()
		h.custom_minimum_size = Vector2(320, 0)
		h.add_theme_constant_override("h_separation", 6)
		h.add_theme_constant_override("v_separation", 6)
		var lbl := UiKit.label("回到：", 14, UiKit.C_DIM)
		h.add_child(lbl)
		for d in saves:
			h.add_child(UiKit.button("第%d天" % d, func(): _load_and_play(d), 14))
		v.add_child(h)
	v.add_child(UiKit.button("连接设置", func(): _open_api_setup(false), 19))
	v.add_child(UiKit.button("退出", func(): get_tree().quit(), 19))
	for c in v.get_children():
		if c is Button:
			c.alignment = HORIZONTAL_ALIGNMENT_LEFT
			c.custom_minimum_size = Vector2(320, 48)
			c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var ok := LlmClient.is_verified()
	var status := UiKit.label("●  模型连接已就绪" if ok else "●  模型未连接　开始游戏前需要先测试连接", 14, UiKit.C_GREEN if ok else UiKit.C_DIM)
	status.position = Vector2(98, 672)
	root.add_child(status)
	_set_screen(root)


func _open_api_setup(then_start: bool) -> void:
	var a := ApiSetup.new()
	_set_overlay(a)
	var ok: bool = await a.done
	_close_overlay()
	if then_start and ok:
		_on_new_game()
	else:
		show_title()


func _on_new_game() -> void:
	if not LlmClient.is_verified():
		_open_api_setup(true)
		return
	GameState.new_game()
	GameState.delete_saves_after(0)
	await _story(Events.opening())
	GameState.save_day()
	enter_hub()


func _load_and_play(d: int) -> void:
	if not LlmClient.is_verified():
		_open_api_setup(false)
		return
	if GameState.load_save(d):
		GameState.delete_saves_after(d)
		enter_hub()


# ------------------------------------------------------------------ 白天

func enter_hub() -> void:
	if GameState.day > GameState.LAST_DAY:
		await _final_day()
		return
	while true:
		if GameState.slot > 3:
			await _night()
			if GameState.day > GameState.LAST_DAY:
				await _final_day()
				return
			continue
		var ev := GameState.pending_event()
		if ev != "":
			await _run_event(ev)
			continue
		break
	_show_town()


func _show_town() -> void:
	var t := TownView.new()
	t.talk_requested.connect(_on_talk)
	t.location_action.connect(_on_location_action)
	t.rest_requested.connect(func():
		GameState.log_journal("休息")
		_finish_slot())
	t.journal_requested.connect(_open_journal)
	t.menu_requested.connect(_open_menu)
	_set_screen(t)


func _finish_slot() -> void:
	GameState.advance_slot()
	enter_hub()


func _on_talk(npc_id: String, loc_id: String) -> void:
	var used := await _talk(npc_id, GameState.locations[loc_id].name, loc_id)
	if used > 0:
		_finish_slot()
	else:
		_show_town()


func _on_location_action(action: String, _loc_id: String) -> void:
	match action:
		"rumor":
			GameState.log_journal("在酒馆打听流言")
			await _story(Events.rumors())
		"investigate":
			await _story(Events.investigate_altar())
	GameState.check_goals()
	_finish_slot()


func _open_journal() -> void:
	_set_overlay(InfoPanels.journal(_close_overlay))


func _open_menu() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(UiKit.dim_layer(0.65))
	var p := UiKit.centered_panel(root, Vector2(440, 330))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UiKit.label("菜单", 22, UiKit.C_GOLD, UiKit.SANS_BOLD))
	v.add_child(UiKit.primary_button("继续游戏", _close_overlay))
	v.add_child(UiKit.button("连接设置", func():
		var a := ApiSetup.new()
		add_child(a)
		await a.done
		a.queue_free()))
	v.add_child(HSeparator.new())
	v.add_child(UiKit.wrap_label("存档只在每天夜间结算后自动保存。现在回到标题，今天的进度将会丢失。", 14, UiKit.C_DIM))
	v.add_child(UiKit.button("回到标题（丢失今天的进度）", show_title))
	_set_overlay(root)


# ------------------------------------------------------------------ 固定事件

func _run_event(ev: String) -> void:
	GameState.mark_event_done()
	match ev:
		"priest_summon":
			await _story(Events.priest_summon_intro())
			await _talk("priest_seraphim", "大神殿·大祭司的书房（他派人把你“请”了过来）", "temple")
			GameState.player_learn("F_HIGH_PRIEST_PLOT")
			GameState.add_event_note("第2天上午，大祭司单独召见了勇者。")
			await _story(Events.priest_summon_after())
			GameState.check_goals()
		"knight_test":
			var choice := await _story(Events.knight_test_intro(), Events.knight_test_choices())
			await _story(Events.knight_test_result(choice))
			GameState.check_goals()
		"sermon":
			if GameState.doubt >= 60:
				await _story(Events.sermon_interrogation_intro())
				await _talk("priest_seraphim", "神殿偏厅（布道大会后，大祭司在众祭司面前“问话”）", "temple")
				var pr: NpcState = GameState.npcs.priest_seraphim
				pr.suspicion = clampi(pr.suspicion + 10, 0, 100)
				GameState.add_event_note("第5天的布道大会后，大祭司当众审问了勇者。")
			else:
				await _story(Events.sermon_calm())
		"nova_visit":
			await _story(Events.nova_visit_intro())
			await _talk("thief_nova", "你的住处（诺娃从窗户翻了进来）", "map")
		"feast":
			var who := await _story(Events.feast_intro(), Events.feast_choices())
			if who != "" and who != "sleep":
				await _talk(who, "王宫宴会厅（出征前夜宴）")
	GameState.advance_slot()


# ------------------------------------------------------------------ 夜间

func _night() -> void:
	var waiting := StoryScreen.new()
	waiting.setup([{"title": "夜幕降临", "text": "王都的灯一盏盏熄灭。
流言在黑暗里走得比白天更快……

" + UiKit.bb_sans("（正在整理今天的记忆）", 15, UiKit.C_DIM), "scene": "map", "tint": Events.NIGHT_TINT}])
	_set_screen(waiting)
	waiting._next_btn.visible = false
	var lines := GameState.night_settlement()
	await NpcBrain.compress_memories()
	var changes: Array = GameState.doubt_today.duplicate()
	var ended_day := GameState.day
	GameState.start_next_day()
	GameState.save_day()
	await _story(Events.night_report(ended_day, lines, changes))


# ------------------------------------------------------------------ 第 8 天

func _final_day() -> void:
	var choice := await _story(Events.final_morning(), Events.final_choices())
	if choice == "flee":
		GameState.flags.final_choice = "flee"
	else:
		GameState.flags.final_choice = "march"
	var e := EndingRules.evaluate(GameState)
	await _story(Events.ending_pages(e), [{"label": "回到标题", "id": "title"}])
	show_title()
