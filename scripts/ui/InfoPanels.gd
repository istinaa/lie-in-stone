class_name InfoPanels
extends RefCounted
## 手记（玩家可见）和调试面板（F1）。


static func journal(on_close: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(UiKit.dim_layer(0.7))
	var panel := UiKit.centered_panel(root, Vector2(1040, 640))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var t := UiKit.title_label("勇者的手记", 28)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var tl := UiKit.label(GameState.time_label() + "　·　疑云值 %d" % GameState.doubt, 15, UiKit.C_DIM, UiKit.SANS_BOLD)
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tl)
	head.add_child(UiKit.button("关闭", on_close, 16))
	v.add_child(head)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(tabs)

	# 目标（任务：黑体）
	var goal := _rich()
	goal.name = "目标"
	var p := EndingRules.check_party(GameState)
	var s := "[font=%s][font_size=21][color=%s]在七天内凑齐讨伐队。第 8 天清晨出征。[/color][/font_size][/font]\n\n" % [UiKit.SANS_BOLD, UiKit.hex(UiKit.C_GOLD)]
	s += "%s　骑士团出兵（莱恩哈特加入讨伐队）\n" % _check(p.knight)
	s += "%s　掌握魔王的弱点（奥斯瓦德加入，或从他那里问出弱点）\n" % _check(p.weakness)
	s += "%s　讨伐队至少 2 人（当前：%s）\n\n" % [_check(p.party.size() >= 2), "、".join(p.party) if p.party.size() > 0 else "无人"]
	s += "[color=%s]疑云值 %d：%s。疑云值太高时，神殿可能会抢先宣布你是“伪勇者”。[/color]\n\n" % [UiKit.hex(UiKit.C_DIM), GameState.doubt, DialogueRules.doubt_desc(GameState.doubt)]
	s += "[font=%s][font_size=19][color=%s]各人的心结[/color][/font_size][/font]　[color=%s]解开一个人的全部心结，就可以邀请他加入讨伐队。[/color]\n" % [UiKit.SANS_BOLD, UiKit.hex(UiKit.C_GOLD), UiKit.hex(UiKit.C_DIM)]
	for id in GoalSystem.PRIORITY:
		var n: NpcState = GameState.npcs[id]
		var status := ""
		if n.is_joined():
			status = "[color=%s]已加入讨伐队[/color]" % UiKit.hex(UiKit.C_GREEN)
		elif GoalSystem.can_join(n):
			status = "[color=%s]可以邀请加入[/color]" % UiKit.hex(UiKit.C_GOLD)
		elif n.stance == "敌对":
			status = "[color=%s]已经和你翻脸[/color]" % UiKit.hex(UiKit.C_RED)
		s += "\n[color=%s][b]%s[/b][/color]　%s　[color=%s]%s[/color]\n" % [UiKit.hex(UiKit.C_GOLD), n.display_name(), status, UiKit.hex(UiKit.C_DIM), GoalSystem.where_text(n, GameState)]
		for g in GoalSystem.visible_goals(n):
			if GoalSystem.is_done(n, g.id):
				s += "　[color=%s]√ %s[/color]\n" % [UiKit.hex(UiKit.C_GREEN), g.title]
			else:
				s += "　○ %s　[color=%s]%s[/color]\n" % [g.title, UiKit.hex(UiKit.C_DIM), g.hint]
	s += "\n[color=%s]提示\n· 对不同的人说的话会被传开，前后矛盾会被拆穿。\n· 坦白不可撤回，但真正的盟友往往来自真相。\n· 在对话里点「出示线索」，把证据和物品拿给对方看；同一样东西，不同的人反应完全不同。[/color]" % UiKit.hex(UiKit.C_DIM)
	goal.text = s
	tabs.add_child(goal)

	# 线索卡
	var cards := ScrollContainer.new()
	cards.name = "线索（%d）" % GameState.cards.size()
	cards.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_theme_constant_override("separation", 16)
	cards.add_child(cv)
	if GameState.cards.is_empty():
		cv.add_child(UiKit.wrap_label("你手里还没有任何线索。和人深谈、参加事件、夜里调查都可能得到线索。拿到以后，可以在对话里出示给别人看。", 15, UiKit.C_DIM))
	for cid in GameState.cards:
		cv.add_child(DialogueBox.card_row(cid))
	tabs.add_child(cards)

	# 已知内幕（证据：黑体）
	var facts := _rich()
	facts.name = "已知内幕"
	var fs := ""
	for f in GameState.player_facts:
		fs += "[font=%s][color=%s]◆ %s[/color][/font]\n[color=#d8cdb9]%s[/color]\n\n" % [UiKit.SANS_BOLD, UiKit.hex(UiKit.C_GOLD), GameState.fact_short(f), GameState.fact_text(f)]
	if fs == "":
		fs = "[color=%s]你还没有掌握任何内幕。[/color]" % UiKit.hex(UiKit.C_DIM)
	facts.text = fs
	tabs.add_child(facts)

	# 人物
	var people := ScrollContainer.new()
	people.name = "人物"
	people.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var pv := VBoxContainer.new()
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_theme_constant_override("separation", 14)
	people.add_child(pv)
	for id in GameState.npcs:
		var n: NpcState = GameState.npcs[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(UiKit.face_badge(id, 72, UiKit.stance_color(n.stance)))
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nh := HBoxContainer.new()
		nh.add_child(UiKit.serif_label(n.display_name(), 20, UiKit.C_GOLD, true))
		var ttl := UiKit.serif_label(str(n.def.title), 14, UiKit.C_DIM)
		ttl.size_flags_vertical = Control.SIZE_SHRINK_END
		nh.add_child(ttl)
		info.add_child(nh)
		var tags := HFlowContainer.new()
		tags.add_theme_constant_override("h_separation", 5)
		tags.add_child(UiKit.chip("态度：" + n.stance, UiKit.stance_color(n.stance), 13))
		for tg in UiKit.npc_tags(n):
			tags.add_child(UiKit.chip(tg[0], tg[1], 13))
		if not bool(n.flags.get("met", false)):
			tags.add_child(UiKit.chip("还没深谈过", UiKit.C_DIM, 13))
		info.add_child(tags)
		var sched := PackedStringArray()
		var sd: Dictionary = n.def.schedule
		for i in 4:
			var loc = sd.get(GameState.SLOT_KEYS[i])
			sched.append("%s %s" % [GameState.SLOTS[i], GameState.locations[loc].name if loc != null else "—"])
		var dz := UiKit.rich(false, 14)
		dz.fit_content = true
		dz.scroll_active = false
		var dl := PackedStringArray()
		for item in GoalSystem.dossier_lines(n):
			dl.append("[color=%s]%s[/color]　%s" % [UiKit.hex(UiKit.C_GOLD_DIM), item[0], item[1]])
		dz.text = "\n".join(dl)
		info.add_child(dz)
		info.add_child(UiKit.wrap_label("你对%s说过 %d 句“声明”　·　常在：%s" % [GoalSystem.pronoun(n), n.player_claims.size(), "　".join(sched)], 13, UiKit.C_DIM))
		row.add_child(info)
		var hb := UiKit.button("对话记录", func(): root.add_child(history(n)), 15)
		hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.disabled = n.transcript.is_empty()
		row.add_child(hb)
		pv.add_child(row)
	tabs.add_child(people)

	# 日志
	var log_t := _rich()
	log_t.name = "日志"
	log_t.text = "\n".join(GameState.journal)
	log_t.scroll_following = true
	tabs.add_child(log_t)
	return root


## 和某个角色的完整对话记录（按天 / 时段 / 地点分组）。自带关闭按钮，关闭时移除自己。
static func history(n: NpcState) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(UiKit.dim_layer(0.7))
	var panel := UiKit.centered_panel(root, Vector2(900, 620))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiKit.face_badge(n.id, 44, UiKit.stance_color(n.stance)))
	var t := UiKit.title_label("与%s的对话记录" % n.display_name(), 24)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(t)
	head.add_child(UiKit.button("关闭", func(): root.queue_free(), 16))
	v.add_child(head)
	v.add_child(HSeparator.new())
	var log_t := UiKit.rich(true, 18)
	log_t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_t.add_theme_constant_override("line_separation", 6)
	log_t.add_theme_constant_override("paragraph_separation", 8)
	log_t.selection_enabled = true
	log_t.text = transcript_bbcode(n, n.transcript)
	v.add_child(log_t)
	log_t.scroll_to_line.call_deferred(maxi(log_t.get_line_count() - 1, 0))
	return root


## 把对话记录转成 BBCode；同一天同一时段同一地点的放在一组，组前加小标题。
static func transcript_bbcode(n: NpcState, entries: Array, dim: bool = false) -> String:
	if entries.is_empty():
		return UiKit.bb_sans("还没有和%s说过话。" % n.display_name(), 15, UiKit.C_DIM)
	var out := PackedStringArray()
	var key := ""
	var gold := UiKit.hex(UiKit.C_GOLD.darkened(0.25) if dim else UiKit.C_GOLD)
	var blue := UiKit.hex(UiKit.C_BLUE.darkened(0.25) if dim else UiKit.C_BLUE)
	var body := "#a8a090" if dim else "#efe6d4"
	for e in entries:
		var k := "%d-%d-%s" % [int(e.get("day", 1)), int(e.get("slot", 0)), str(e.get("loc", ""))]
		if k != key:
			key = k
			var slot_name: String = GameState.SLOTS[clampi(int(e.get("slot", 0)), 0, 3)]
			var loc := str(e.get("loc", ""))
			out.append(UiKit.bb_sans("—— 第 %d 天 · %s%s ——" % [int(e.get("day", 1)), slot_name, ("　" + loc) if loc != "" else ""], 13, UiKit.C_GOLD_DIM))
		var txt := str(e.get("text", "")).replace("[", "［").replace("]", "］")
		match str(e.get("who", "")):
			"player":
				out.append("[color=%s][b]你[/b][/color]　[color=%s]%s[/color]" % [blue, body, txt])
			"npc":
				out.append("[color=%s][b]%s[/b][/color]　[color=%s]%s[/color]" % [gold, n.display_name(), body, txt])
			_:
				out.append(UiKit.bb_sans("◆ " + txt, 14, UiKit.C_PURPLE.darkened(0.2) if dim else UiKit.C_PURPLE))
	return "\n".join(out)


static func debug(gs: Node) -> String:
	var s := "[font_size=13][color=#e0b040]调试面板（F1）[/color]\n"
	s += "%s  疑云 %d  事实 %s\n" % [gs.time_label(), gs.doubt, ",".join(gs.player_facts)]
	for id in gs.npcs:
		var n: NpcState = gs.npcs[id]
		var fl := PackedStringArray()
		for k in n.flags:
			if n.flags[k] is bool and n.flags[k]:
				fl.append(k)
		s += "[color=#80b0f0]%s[/color] 信%d 疑%d 好%d %s\n" % [n.display_name(), n.trust, n.suspicion, n.affinity, n.stance]
		if fl.size() > 0:
			s += "  [color=#c8a0f0]%s[/color]\n" % ",".join(fl)
	s += "[color=#a89fb8]LLM：请求 %d 失败 %d 延迟 %dms\ntoken 输入 %d（缓存命中 %d） 输出 %d%s[/color][/font_size]" % [
		LlmClient.request_count, LlmClient.failed_count, LlmClient.last_latency_ms,
		LlmClient.total_prompt_tokens, LlmClient.total_cache_hit_tokens, LlmClient.total_completion_tokens,
		"  [MOCK]" if LlmClient.mock else ""]
	return s


static func _rich() -> RichTextLabel:
	var r := UiKit.rich(false, 17)
	r.add_theme_constant_override("line_separation", 6)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return r


static func _check(ok: bool) -> String:
	return "[color=%s]√[/color]" % UiKit.hex(UiKit.C_GREEN) if ok else "[color=%s]×[/color]" % UiKit.hex(UiKit.C_RED)
