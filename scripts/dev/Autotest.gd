extends Node
## 开发用自检（不面向玩家）。
##   godot --headless --path . -- --mock-llm --autotest
##   godot --path . -- --mock-llm --shots=<目录>     （截图，需要窗口）

var fails := 0
var checks := 0
var main: Control


func run(m: Control, args: PackedStringArray) -> void:
	main = m
	await get_tree().process_frame
	var shots := ""
	for a in args:
		if a.begins_with("--shots="):
			shots = a.trim_prefix("--shots=")
	if shots != "":
		await _shots(shots)
		get_tree().quit(0)
		return
	await _test_rules()
	await _test_gossip_and_save()
	_test_endings()
	await _test_full_week()
	await _test_ui()
	await _test_flow()
	print("AUTOTEST %s  (%d checks, %d failed)" % ["PASS" if fails == 0 else "FAIL", checks, fails])
	get_tree().quit(1 if fails > 0 else 0)


func ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("  ✖ " + what)
	else:
		print("  ✔ " + what)


func _resp(over: Dictionary) -> Dictionary:
	var base := {"reply": "嗯。", "emotion": "neutral", "action": "none", "trust_delta": 0, "suspicion_delta": 0,
		"affinity_delta": 0, "player_claims": [], "player_confessed": false, "player_revealed_facts": [],
		"noticed_contradiction": null, "suggested_replies": []}
	base.merge(over, true)
	return base


func _test_rules() -> void:
	print("[rules]")
	GameState.new_game()
	ok(GameState.npcs.size() == 5, "5 个 NPC 已加载")
	var kn: NpcState = GameState.npcs.knight_reinhardt
	var mia: NpcState = GameState.npcs.apprentice_mia
	ok(kn.stance == "试探", "骑士初始为试探（%s）" % kn.stance)
	ok(mia.stance == "崇拜", "米娅初始为崇拜（%s）" % mia.stance)
	ok(GameState.npcs.scholar_oswald.stance == "观望", "学者初始为观望")

	var r := DialogueRules.sanitize(_resp({"trust_delta": 80, "suspicion_delta": -99, "emotion": "furious", "action": "join_party",
		"suggested_replies": [{"tactic": "坦白", "text": "我没有神力"}, {"tactic": "说服", "text": "a"}, {"tactic": "说服", "text": "b"}, {"tactic": "瞎编", "text": "c"}]}), kn, GameState.player_facts)
	ok(r.trust_delta == 15 and r.suspicion_delta == -15, "数值限幅 ±15")
	ok(r.emotion == "neutral", "未知表情回退 neutral")
	ok(r.action == "none", "试探阶段不允许 join_party")
	ok(r.suggested_replies.size() == 2 and r.suggested_replies[0].tactic == "坦白", "骑士怀疑≥80 时允许坦白选项，过滤重复/非法策略")
	var sch: NpcState = GameState.npcs.scholar_oswald
	sch.trust = 30
	sch.suspicion = 50
	var r2 := DialogueRules.sanitize(_resp({"suggested_replies": [{"tactic": "坦白", "text": "x"}]}), sch, GameState.player_facts)
	ok(r2.suggested_replies.is_empty(), "条件不满足时过滤坦白选项")
	ok(DialogueRules.sanitize({"reply": ""}, kn, []).is_empty(), "缺少台词视为无效")
	var r3 := DialogueRules.sanitize(_resp({"player_revealed_facts": ["F_DEMON_WEAKNESS", "F_PLAYER_NO_POWER"]}), kn, GameState.player_facts)
	ok(r3.player_revealed_facts == ["F_PLAYER_NO_POWER"], "玩家只能透露自己知道的事实")

	# 坦白
	kn.trust = 45
	var notes := DialogueRules.apply(kn, DialogueRules.sanitize(_resp({"player_confessed": true, "trust_delta": 10}), kn, GameState.player_facts), GameState, "我没有神力")
	ok(kn.knows("F_PLAYER_NO_POWER") and kn.flags.knows_truth, "坦白写入事实")
	ok(kn.stance == "共犯", "信任>50 且知情 → 共犯（%s，信任 %d）" % [kn.stance, kn.trust])
	ok(GameState.flags.confessed_to.has("knight_reinhardt"), "记录坦白对象")
	ok(notes.size() >= 1, "坦白产生提示")
	# 心结：坦白完成了骑士的第一个心结，但还没有作战计划 → 不能加入
	ok(GoalSystem.is_done(kn, "proof"), "向骑士坦白 → 完成心结「诚意或本事」")
	DialogueRules.apply(kn, DialogueRules.sanitize(_resp({"action": "join_party"}), kn, GameState.player_facts), GameState, "")
	ok(not kn.is_joined(), "心结没解开时，模型给 join_party 也不会加入")
	# 学者：坦白 → 说出魔王弱点（线索卡 + 事实）
	sch.flags.player_confessed = true
	var gnotes := GoalSystem.check_all(GameState)
	ok(GameState.player_knows("F_DEMON_WEAKNESS") and GameState.cards.has("C_WEAKNESS"), "学者的心结解开 → 得到魔王弱点和线索卡")
	ok(gnotes.size() >= 2, "目标完成有提示（%d 条）" % gnotes.size())
	# 出示弱点给骑士 → 心结全部解开 → 可以加入
	var eff := GoalSystem.apply_present(GameState, "C_WEAKNESS", kn)
	ok(eff.get("trust", 0) == 15, "出示线索的数值来自数据表")
	GoalSystem.check_all(GameState)
	ok(GoalSystem.can_join(kn), "骑士的心结都解开了 → 可以邀请加入")
	DialogueRules.apply(kn, DialogueRules.sanitize(_resp({"action": "join_party"}), kn, GameState.player_facts), GameState, "")
	ok(kn.is_joined(), "心结解开后可以加入讨伐队")
	GoalSystem.check_all(GameState)
	ok(GoalSystem.is_done(sch, "odds"), "骑士加入 → 学者的心结「讨伐有胜算」自动完成")
	ok(GoalSystem.quest_lines(GameState).size() > 0, "“接下来”面板有内容")
	# 矛盾
	var before := sch.suspicion
	DialogueRules.apply(sch, DialogueRules.sanitize(_resp({"noticed_contradiction": "你对米娅说的是冰冷的"}), sch, GameState.player_facts), GameState, "")
	ok(sch.suspicion == before + 5 and sch.contradictions.size() == 1, "发现矛盾 → 怀疑 +5")

	# 回归：模型用 0/1/"true" 表示布尔；flags 里混有整数（refused_count / confessed_day）
	var t1 := DialogueRules.sanitize(_resp({"player_confessed": 1}), sch, GameState.player_facts)
	var t0 := DialogueRules.sanitize(_resp({"player_confessed": 0}), sch, GameState.player_facts)
	var ts := DialogueRules.sanitize(_resp({"player_confessed": "false"}), sch, GameState.player_facts)
	ok(t1.player_confessed == true and t0.player_confessed == false and ts.player_confessed == false, "player_confessed 兼容 0/1/字符串")
	DialogueRules.apply(sch, DialogueRules.sanitize(_resp({"action": "refuse"}), sch, GameState.player_facts), GameState, "")
	ok(sch.flags.get("refused_count") is int, "refuse 后 flags 里有整数")
	var dbg := InfoPanels.debug(GameState)
	ok(dbg.contains("奥斯瓦德"), "调试面板能处理整数 flags")
	var jr := InfoPanels.journal(func(): pass)
	jr.free()

	# 真实的 NpcBrain 流程（mock 模型）
	GameState.new_game()
	var res: Dictionary = await NpcBrain.run_turn(GameState.npcs.apprentice_mia, 0, "", "大神殿")
	ok(res.ok, "开场白请求成功")
	ok(GameState.npcs.apprentice_mia.recent_dialogue.size() == 1, "开场白只记录 NPC 台词")
	res = await NpcBrain.run_turn(GameState.npcs.apprentice_mia, 1, "我的神力能召唤雷电", "大神殿")
	ok(res.ok and GameState.npcs.apprentice_mia.player_claims.size() == 1, "提取玩家声明进谎言台账")
	var tmia: NpcState = GameState.npcs.apprentice_mia
	ok(tmia.transcript.size() >= 3 and tmia.transcript[1].who == "player", "完整对话记录（%d 条）" % tmia.transcript.size())
	ok(NpcBrain.build_state_prompt(tmia, 2, "他问了三遍", "大神殿").contains("【你刚才说的】"), "提示词把 NPC 上一句和勇者的回答放在一起")
	var hv := InfoPanels.history(tmia)
	ok(hv != null and InfoPanels.transcript_bbcode(tmia, tmia.transcript).contains("第 1 天"), "对话记录界面")
	hv.free()
	var mia_d := tmia.to_dict()
	ok(mia_d.has("transcript"), "对话记录写进存档")
	# 出示线索 / 邀请加入（mock 模型走完整流程）
	var nova: NpcState = GameState.npcs.thief_nova
	GoalSystem.give_card(GameState, "C_PRIEST_THREAT")
	GoalSystem.give_card(GameState, "C_PURSE")
	ok(NpcBrain.build_state_prompt(nova, 1, "（拿出）", "酒馆", {"type": "present", "card": "C_PRIEST_THREAT"}).contains("【随之而来】"), "出示前预演心结，写进提示词")
	var pr1: Dictionary = await NpcBrain.run_turn(nova, 1, "（拿出「大祭司的“关照”」）", "金麦酒馆", {"type": "present", "card": "C_PRIEST_THREAT"})
	ok(pr1.ok and GoalSystem.is_done(nova, "not_pawn") and GameState.cards.has("C_NOVA_TESTIMONY"), "向诺娃出示大祭司的关照 → 得到诺娃的证词")
	var pr2: Dictionary = await NpcBrain.run_turn(nova, 2, "（拿出「神殿的津贴」）", "金麦酒馆", {"type": "present", "card": "C_PURSE"})
	ok(pr2.ok and not GameState.cards.has("C_PURSE") and bool(GameState.flags.get("escape_offered", false)), "付钱给诺娃 → 钱袋交出、拿到退路")
	var pr3: Dictionary = await NpcBrain.run_turn(nova, 3, "跟我走吧", "金麦酒馆", {"type": "invite"})
	ok(pr3.ok and nova.is_joined(), "心结解开后邀请诺娃 → 加入讨伐队")
	var mia_inv: Dictionary = await NpcBrain.run_turn(tmia, 2, "加入我吧", "大神殿", {"type": "invite"})
	ok(mia_inv.ok and not tmia.is_joined() and mia_inv.result.action != "join_party", "心结未解开时邀请米娅 → 被拒绝")
	ok(NpcBrain.build_state_prompt(tmia, 3, "x", "大神殿", {"type": "invite"}).contains("你还在等什么"), "拒绝时提示词里写明还差什么")
	var prompt := NpcBrain.build_state_prompt(GameState.npcs.apprentice_mia, 2, "测试", "大神殿")
	ok(prompt.contains("召唤雷电") and prompt.contains("json"), "状态提示词包含台账与 json 字样")
	var sys := NpcBrain.build_system_prompt(GameState.npcs.thief_nova)
	ok(sys.contains("诺娃") and not sys.contains("{name}"), "系统提示词模板替换完整")
	var p_mia := NpcBrain.build_state_prompt(GameState.npcs.apprentice_mia, 1, "x", "y")
	ok(not p_mia.contains("黑曜心核") or p_mia.find("黑曜心核") > p_mia.find("【勇者可能透露的内幕】"), "米娅的已知内幕里没有她不该知道的事实")


func _test_gossip_and_save() -> void:
	print("[gossip/save]")
	GameState.new_game()
	var mia: NpcState = GameState.npcs.apprentice_mia
	mia.player_claims.append({"text": "我能召唤雷电", "topic": "power", "day": 1, "spread": false})
	var lines := GameState.night_settlement()
	var sch: NpcState = GameState.npcs.scholar_oswald
	ok(sch.heard_claims.size() == 1 and sch.heard_claims[0].text.begins_with("我能召唤雷电"), "米娅的话传到了学者耳中")
	ok(lines.size() >= 1, "夜间有传闻文本")
	GameState.night_settlement()
	ok(sch.heard_claims.size() == 1, "同一声明不会重复传播")

	# 米娅被伤透 → 泄露真相
	GameState.new_game()
	mia = GameState.npcs.apprentice_mia
	mia.trust = 30
	DialogueRules.apply(mia, DialogueRules.sanitize(_resp({"player_confessed": true, "trust_delta": -10}), mia, GameState.player_facts), GameState, "")
	var d0 := GameState.doubt
	GameState.night_settlement()
	ok(GameState.doubt >= d0 + 15, "米娅不是共犯时会泄露真相（疑云 %d → %d）" % [d0, GameState.doubt])
	ok(GameState.npcs.knight_reinhardt.knows("F_PLAYER_NO_POWER"), "骑士从米娅那里得知真相")

	# 存档往返
	GameState.new_game()
	GameState.npcs.knight_reinhardt.trust = 77
	GameState.npcs.knight_reinhardt.flags.joined = true
	GameState.npcs.knight_reinhardt.stance = DialogueRules.compute_stance(GameState.npcs.knight_reinhardt)
	GameState.player_learn("F_DEMON_WEAKNESS")
	GameState.start_next_day()
	GameState.save_day()
	var snap := JSON.stringify(GameState.to_dict().npcs)
	GameState.new_game()
	ok(GameState.load_save(2), "读取第 2 天存档")
	ok(GameState.day == 2 and GameState.slot == 0, "存档时间正确")
	ok(GameState.npcs.knight_reinhardt.trust == 77 and GameState.npcs.knight_reinhardt.is_joined(), "NPC 状态恢复")
	ok(GameState.player_knows("F_DEMON_WEAKNESS"), "玩家事实恢复")
	var snap2 := JSON.stringify(GameState.to_dict().npcs)
	ok(snap2 == snap, "存档前后 NPC 数据一致")
	if snap2 != snap:
		print(snap.left(600), "
----
", snap2.left(600))
	GameState.delete_saves_after(0)
	ok(GameState.list_saves().is_empty(), "清理测试存档")


func _setn(id: String, trust: int, susp: int, joined: bool, knows: bool) -> void:
	var n: NpcState = GameState.npcs[id]
	n.trust = trust
	n.suspicion = susp
	n.flags.joined = joined
	n.flags.knows_truth = knows
	n.stance = DialogueRules.compute_stance(n)


func _test_endings() -> void:
	print("[endings]")
	GameState.new_game()
	GameState.flags.final_choice = "march"
	GameState.doubt = 30
	ok(EndingRules.evaluate(GameState).key == "martyr", "什么都没做 → 壮烈殉国")
	GameState.doubt = 85
	ok(EndingRules.evaluate(GameState).key == "scapegoat", "疑云爆表且无共犯 → 替罪羊")
	GameState.doubt = 30
	_setn("knight_reinhardt", 70, 30, true, false)
	_setn("scholar_oswald", 70, 30, true, false)
	ok(EndingRules.evaluate(GameState).key == "perfect_lie", "骗来了骑士和学者 → 完美的谎言")
	_setn("knight_reinhardt", 70, 100, true, true)
	_setn("scholar_oswald", 70, 100, true, true)
	ok(EndingRules.evaluate(GameState).key == "many_swords", "两名共犯 + 战力 → 众人之剑")
	GameState.flags.final_choice = "flee"
	ok(EndingRules.evaluate(GameState).key == "flee", "选择逃走 → 逃兵")
	GameState.flags.final_choice = "march"
	_setn("scholar_oswald", 70, 30, false, false)
	ok(EndingRules.evaluate(GameState).key == "martyr", "只有骑士、不知道弱点 → 壮烈殉国")
	GameState.player_learn("F_DEMON_WEAKNESS")
	_setn("apprentice_mia", 90, 0, true, false)
	ok(EndingRules.evaluate(GameState).key == "perfect_lie", "骑士(共犯)+米娅+弱点，共犯不足 2 → 完美的谎言")


func _test_full_week() -> void:
	print("[week]")
	GameState.new_game()
	var safety := 0
	while GameState.day <= GameState.LAST_DAY and safety < 100:
		safety += 1
		if GameState.slot > 3:
			GameState.night_settlement()
			await NpcBrain.compress_memories()
			GameState.start_next_day()
			GameState.save_day()
			continue
		var ev := GameState.pending_event()
		if ev != "":
			GameState.mark_event_done()
			if ev == "knight_test":
				Events.knight_test_result("swing")
			elif ev == "sermon" and GameState.doubt < 60:
				Events.sermon_calm()
			GameState.advance_slot()
			continue
		# 找一个在场的人聊 2 句
		var talked := false
		for loc in GameState.locations:
			var here := GameState.npcs_at(loc)
			if here.size() > 0:
				var n: NpcState = GameState.npcs[here[0]]
				await NpcBrain.run_turn(n, 0, "", loc)
				await NpcBrain.run_turn(n, 1, "我的神力很强", loc)
				await NpcBrain.run_turn(n, 2, "请加入讨伐队", loc)
				talked = true
				break
		if not talked:
			Events.rumors()
		GameState.advance_slot()
	ok(GameState.day == GameState.LAST_DAY + 1, "七天走完（第 %d 天）" % GameState.day)
	ok(GameState.list_saves().size() == 7, "每天一份存档（%d 份）" % GameState.list_saves().size())
	GameState.flags.final_choice = "march"
	var e := EndingRules.evaluate(GameState)
	ok(e.has("title"), "结局判定：%s" % e.get("title", "?"))
	ok(Events.ending_pages(e).size() == 2, "结局文本")
	GameState.delete_saves_after(0)


func _test_ui() -> void:
	print("[ui]")
	GameState.new_game()
	main._show_town()
	await _frames(3)
	ok(main.screen is TownView, "地图界面")
	(main.screen as TownView)._open_location("training")
	await _frames(2)
	main._on_talk("knight_reinhardt", "training")
	await _frames(2)
	var dlg = main.overlay
	ok(dlg is DialogueBox, "对话界面")
	await _wait_idle(dlg)
	ok(dlg.exchanges == 1, "对话开场白已显示")
	dlg._input.text = "我感受到了神的声音"
	dlg._on_send()
	await _wait_idle(dlg)
	ok(dlg.turn == 1 and dlg._sugg_box.get_child_count() > 0, "发送一句并显示推荐选项")
	dlg._on_leave()
	await _frames(2)
	ok(dlg._summary != null, "离开时显示谈话小结")
	dlg._on_leave()
	await _frames(3)
	ok(GameState.slot == 2, "谈话消耗一个时段（现在是%s）" % GameState.slot_name())
	main._open_journal()
	await _frames(2)
	ok(main.overlay != null, "手记界面")
	main._close_overlay()
	main._set_overlay(ApiSetup.new())
	await _frames(2)
	main._close_overlay()
	var s := StoryScreen.new()
	s.setup(Events.knight_test_intro(), Events.knight_test_choices())
	main._set_screen(s)
	await _frames(2)
	ok(s._choice_box.get_child_count() == 5, "考验选项")
	var long_night := StoryScreen.new()
	long_night.setup(Events.night_report(1, _many_rumors(), GameState.doubt_today))
	main._set_screen(long_night)
	await _frames(5)
	ok(long_night._panel.get_global_rect().position.y >= 0 and long_night._panel.get_global_rect().end.y <= long_night.size.y, "传闻很多时夜间结算框不出屏幕")
	var badge := UiKit.face_badge("hero", 56)
	var hb := HBoxContainer.new()
	hb.add_child(badge)
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(10, 140)
	hb.add_child(tall)
	add_child(hb)
	await _frames(2)
	ok(absf(badge.size.x - badge.size.y) < 1.0, "小头像在高行里仍是 1:1（%s）" % badge.size)
	hb.queue_free()
	main.show_title()
	await _frames(2)
	ok(main.screen != null, "标题界面")


func _many_rumors() -> Array:
	var a := []
	for i in 14:
		a.append("第 %d 条传闻：米娅把你说的「我能召唤雷电，还能一剑劈开城墙」告诉了奥斯瓦德、莱恩哈特、塞拉菲姆。" % (i + 1))
	return a


func _wait_idle(dlg) -> void:
	for i in 300:
		await get_tree().process_frame
		if not dlg.busy:
			return


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


# ---------------------------------------------------------------- 截图

func _snap(dir: String, name: String) -> void:
	await _frames(20)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	print("shot ", name)


func _shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	main.show_title()
	await _snap(dir, "01_title")
	GameState.new_game()
	var s := StoryScreen.new()
	s.setup(Events.opening())
	main._set_screen(s)
	await _frames(200)
	await _snap(dir, "02_opening")
	s._text.visible_characters = -1
	s._on_next()
	await _frames(400)
	await _snap(dir, "02b_opening_cg")
	s._text.visible_characters = -1
	s._on_next()
	s._text.visible_characters = -1
	s._on_next()
	await _frames(400)
	await _snap(dir, "02c_goal")
	main._show_town()
	await _snap(dir, "03_town")
	(main.screen as TownView)._open_location("library")
	await _snap(dir, "04_location")
	main._show_town()
	(main.screen as TownView)._open_location("training")
	await _snap(dir, "04b_location_training")
	main._show_town()
	main._on_talk("scholar_oswald", "library")
	var dlg = main.overlay
	await _wait_idle(dlg)
	dlg._input.text = "我在仪式上听见了神的声音，它是温暖的。"
	dlg._on_send()
	await _wait_idle(dlg)
	await _snap(dir, "05_dialogue")
	dlg._open_card_picker()
	await _snap(dir, "05b_card_picker")
	dlg.get_child(dlg.get_child_count() - 1).queue_free()  # 关掉线索选择框
	dlg._present("C_RITUAL_DOUBTS")
	await _wait_idle(dlg)
	await _snap(dir, "05c_presented")
	dlg._on_leave()
	await _snap(dir, "05d_summary")
	dlg._on_leave()
	await _frames(5)
	main._open_journal()
	await _snap(dir, "06_journal")
	main._close_overlay()
	main.show_debug = true
	main._update_debug_visibility()
	await _snap(dir, "07_town_afternoon_debug")
	var s2 := StoryScreen.new()
	s2.setup(Events.knight_test_intro(), Events.knight_test_choices())
	main._set_screen(s2)
	await _frames(200)
	await _snap(dir, "08_test")
	GameState.npcs.apprentice_mia.player_claims.append({"text": "我能召唤雷电", "topic": "power", "day": 1, "spread": false})
	var lines := GameState.night_settlement()
	var s3 := StoryScreen.new()
	s3.setup(Events.night_report(1, lines, GameState.doubt_today))
	main._set_screen(s3)
	await _frames(300)
	await _snap(dir, "09_night")
	var s3b := StoryScreen.new()
	s3b.setup(Events.night_report(1, _many_rumors(), GameState.doubt_today))
	main._set_screen(s3b)
	await _frames(60)
	await _snap(dir, "09b_night_long")
	GameState.slot = 3
	main._show_town()
	await _snap(dir, "10_town_night")
	main._set_overlay(ApiSetup.new())
	await _snap(dir, "11_api")
	main._close_overlay()
	var e := EndingRules.evaluate(GameState)
	e.key = "many_swords"
	e.title = "众人之剑"
	var s4 := StoryScreen.new()
	s4.setup(Events.ending_pages(e))
	main._set_screen(s4)
	await _frames(600)
	await _snap(dir, "12_ending")
	s4._text.visible_characters = -1
	s4._on_next()
	await _frames(400)
	await _snap(dir, "13_ending_summary")
	var s5 := StoryScreen.new()
	GameState.npcs.thief_nova.flags.promised_help = true
	s5.setup(Events.investigate_altar())
	main._set_screen(s5)
	await _frames(400)
	await _snap(dir, "14_device")
	GameState.slot = 1
	main._show_town()
	(main.screen as TownView)._open_location("tavern")
	await _snap(dir, "15_location_tavern")


func _test_flow() -> void:
	## 通过真实的 UI 流程从新游戏一路点到结局。
	print("[flow]")
	GameState.delete_saves_after(0)
	main._on_new_game()
	var steps := 0
	var ending_seen := ""
	var events_seen := {}
	while steps < 4000:
		steps += 1
		await get_tree().process_frame
		var sc = main.screen
		var ov = main.overlay
		if ov is DialogueBox:
			if ov.busy:
				continue
			if ov.ended or ov.turn >= 2:
				ov._on_leave()
			else:
				ov._input.text = "请加入讨伐队，我的神力很强。"
				ov._on_send()
			continue
		if sc is StoryScreen:
			var title: String = str(sc.pages[sc._idx].get("title", ""))
			events_seen[title] = true
			if title.begins_with("结局"):
				ending_seen = title
			if sc._choice_box.get_child_count() > 0 and not sc._next_btn.visible:
				for b in sc._choice_box.get_children():
					if b is Button and not b.disabled and not b.is_queued_for_deletion():
						b.pressed.emit()
						break
			else:
				sc._text.visible_characters = -1
				sc._on_next()
			continue
		if sc is TownView:
			var talked := false
			for loc in GameState.locations:
				var here := GameState.npcs_at(loc)
				if here.size() > 0 and randf() < 0.7:
					sc.talk_requested.emit(here[0], loc)
					talked = true
					break
			if not talked:
				sc.rest_requested.emit()
			continue
		if ending_seen != "":
			break
	ok(ending_seen != "", "完整流程走到了结局：%s（%d 帧）" % [ending_seen, steps])
	ok(events_seen.has("第 3 天 · 下午　骑士团的公开考验"), "经历了第 3 天考验")
	ok(events_seen.has("第 7 天 · 夜晚　出征前夜宴"), "经历了出征前夜宴")
	ok(GameState.list_saves().size() >= 7, "流程中自动存档 %d 份" % GameState.list_saves().size())
	GameState.delete_saves_after(0)
