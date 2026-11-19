class_name Events
extends RefCounted
## 预写的剧情文本（不依赖网络）+ 由代码判定结果的事件（考验、调查）。

const NIGHT_BG := Color("#0e0a16")
const NIGHT_TINT := Color(0.42, 0.48, 0.78)
const DAWN_TINT := Color(1.0, 0.82, 0.7)


static func opening() -> Array:
	return [
		{"title": "第 1 天 · 上午　圣剑择主", "portrait": "hero", "emotion": "nervous", "scene": "temple",
		 "text": "大神殿的钟敲了十二下。\n\n你本来只是神殿后厨的杂役——没有父母，没有姓氏，连名字都是老厨娘随口起的。今天清晨，一位祭司把你从柴房里拽出来，给你换上一身不合身的礼服，只交代了一句：\n\n[color=#e0b040]“站到那个位置。别说话。”[/color]"},
		{"title": "第 1 天 · 上午　圣剑择主", "portrait": "hero", "emotion": "surprised", "cg": "ritual",
		 "text": "你把手放在剑柄上。\n\n圣剑亮了。\n\n光从剑座里涌出来，照亮了整座正殿。广场上几千人同时跪下。第一排有个系着发带、怀里抱着法典的小姑娘哭得一塌糊涂，一边哭一边喊：[color=#e0b040]“勇者大人！”[/color]\n\n可你什么都没感觉到。没有温暖，没有声音，没有神。\n\n[color=#a89fb8]你很清楚：你没有任何神力。这场仪式是假的。[/color]"},
		{"title": "大祭司塞拉菲姆", "portrait": "priest_seraphim", "emotion": "happy", "scene": "temple",
		 "text": "大祭司扶起你，用只有你听得见的声音说：\n\n[color=#e0b040]“恭喜您，神选之人。七天后，您将率领讨伐队出征北境。在那之前……请务必谨言慎行。神殿会照顾好您的一切。”[/color]\n\n他的手很凉。\n\n你忽然明白了：一个无依无靠的杂役，就算死在北境，也不会有人追究。"},
		{"title": "你的目标", "portrait": "hero", "emotion": "neutral", "scene": "map", "font": "sans",
		 "text": "[b]在七天内凑齐一支真正能打败魔王的讨伐队。第 8 天清晨出征。[/b]\n\n· 每天分为上午 / 下午 / 傍晚 / 夜晚 4 个时段，每个时段只能做一件事。\n· 每个人都有[color=#e0b040]心结[/color]：想要的东西、在等的答案。解开一个人的全部心结，就能邀请他加入讨伐队。地图右上角的「接下来」会告诉你下一步该找谁、做什么。\n· 和人交谈时，可以[color=#e0b040]用自己的话[/color]说（也可以点推荐说法再修改），也可以「出示线索」，把拿到的证据和物品给对方看。每次谈话最多 8 句。\n· 他们会记住你说过的话，会互相传话，也会当场拆穿你。撒谎、表演、坦白、交易……怎么说由你决定。坦白不可撤回。\n· 每天夜里自动存档，白天不能存档。\n\n[color=#a89fb8]今天上午的仪式已经结束。现在是第 1 天下午。可以先去图书馆找奥斯瓦德——听说他对仪式起了疑心。[/color]"},
	]


static func priest_summon_intro() -> Array:
	return [{"title": "第 2 天 · 上午　大祭司的“关照”", "portrait": "priest_seraphim", "emotion": "neutral", "scene": "temple", "tint": Color(0.7, 0.75, 0.95),
		"text": "天还没亮，两名神殿护卫就站在了你的门口。\n\n[color=#e0b040]“大祭司想和勇者大人聊聊。”[/color]\n\n他们没有说“请”，也没有给你拒绝的余地。"}]


static func priest_summon_after() -> Array:
	GoalSystem.give_card(GameState, "C_PRIEST_THREAT")
	GoalSystem.give_card(GameState, "C_PURSE")
	return [{"title": "离开书房的时候", "portrait": "priest_seraphim", "emotion": "neutral", "scene": "temple", "tint": Color(0.7, 0.75, 0.95),
		"text": "一名祭司送你出门，往你手里塞了一袋沉甸甸的金币：[color=#e0b040]“大祭司大人的心意，出征前的置装费。”[/color]\n\n走在回廊上，你想起刚才那场谈话：他反复问你仪式上“感觉到了什么”，问了三遍。他在确认你会不会说漏嘴。\n\n[color=#70c080]获得线索：「大祭司的“关照”」「神殿的津贴」。可以在对话里出示给别人看。[/color]"}]


static func knight_test_intro() -> Array:
	var pages: Array = [{"title": "第 3 天 · 下午　骑士团的公开考验", "portrait": "knight_reinhardt", "emotion": "skeptical", "cg": "trial",
		"text": "训练场四周挤满了骑士和看热闹的市民。场地中央立着一根包了铁皮的橡木桩。\n\n莱恩哈特抱着双臂：[color=#e0b040]“勇者大人，三百个弟兄要把命交给你。请用圣剑劈开这根木桩，让大家看看神的力量。”[/color]\n\n所有人都在看着你。"}]
	return pages


static func knight_test_choices() -> Array:
	var npcs: Dictionary = GameState.npcs
	var mia: NpcState = npcs.apprentice_mia
	var nova: NpcState = npcs.thief_nova
	var kn: NpcState = npcs.knight_reinhardt
	var mia_ok := bool(mia.flags.get("promised_help", false)) or mia.is_accomplice()
	var nova_ok := bool(nova.flags.get("promised_help", false)) or nova.is_accomplice()
	var kn_ok := bool(kn.flags.get("knows_truth", false)) and kn.trust > 50
	return [
		{"id": "swing", "label": "〔表演〕硬着头皮挥下圣剑"},
		{"id": "mia", "label": "〔作弊〕给米娅使眼色，让她暗中放出光魔法" if mia_ok else "〔作弊〕让米娅暗中放光魔法（需要她事先答应帮你）", "disabled": not mia_ok},
		{"id": "nova", "label": "〔作弊〕诺娃昨晚已经把木桩锯断了大半" if nova_ok else "〔作弊〕让诺娃提前对木桩动手脚（需要她事先答应帮你）", "disabled": not nova_ok},
		{"id": "knight", "label": "〔共犯〕按你和莱恩哈特私下商量好的来" if kn_ok else "〔共犯〕和莱恩哈特串通（需要他知道真相并且信任你）", "disabled": not kn_ok},
		{"id": "refuse", "label": "〔转移〕“神力不是用来给人表演的。”"},
	]


static func knight_test_result(choice: String) -> Array:
	var gs := GameState
	var npcs: Dictionary = gs.npcs
	var kn: NpcState = npcs.knight_reinhardt
	var mia: NpcState = npcs.apprentice_mia
	var sch: NpcState = npcs.scholar_oswald
	var text := ""
	var emo := "neutral"
	match choice:
		"swing":
			kn.suspicion = clampi(kn.suspicion + 15, 0, 100)
			kn.trust = clampi(kn.trust - 10, 0, 100)
			mia.suspicion = clampi(mia.suspicion + 10, 0, 100)
			sch.suspicion = clampi(sch.suspicion + 10, 0, 100)
			gs.add_doubt(15, "公开考验失败")
			gs.add_event_note("第3天骑士团的公开考验中，勇者挥下圣剑，木桩纹丝不动，圣剑也没有发光。")
			gs.log_journal("公开考验：失败。")
			emo = "angry"
			text = "你用尽全身力气劈了下去。\n\n“铛”的一声，剑被弹开，虎口震得发麻。木桩上只留下一道白印。圣剑没有发光。\n\n人群安静得可怕。莱恩哈特一言不发地转身离开了。\n\n[color=#e06060]疑云值 +15。莱恩哈特更加怀疑你了，在场的米娅和奥斯瓦德也看见了。[/color]"
		"mia":
			kn.suspicion = clampi(kn.suspicion - 15, 0, 100)
			gs.add_doubt(-10, "公开考验“成功”")
			gs.add_event_note("第3天骑士团的公开考验中，圣剑在勇者手中放出耀眼的光，木桩应声倒地。")
			if not mia.knows("F_PLAYER_NO_POWER"):
				mia.trust = clampi(mia.trust + 5, 0, 100)
			var extra := ""
			if not sch.is_accomplice():
				sch.suspicion = clampi(sch.suspicion + 8, 0, 100)
				extra = "\n\n只有人群后面的奥斯瓦德眯起了眼睛——那道光的颜色，和神殿祷告时的照明术一模一样。"
			mia.flags.helped_test = true
			gs.flags.test_passed = true
			gs.log_journal("公开考验：米娅暗中放了光魔法，“通过”。")
			emo = "surprised"
			text = "你举起剑的瞬间，人群里的米娅悄悄抬起了手。\n\n一道白光在剑身上炸开，所有人都被晃得睁不开眼。等光散去，木桩已经倒在地上——那是你闭着眼用肩膀撞倒的。\n\n欢呼声几乎掀翻了训练场。莱恩哈特沉默了很久，最后说：“……算你过关。”%s\n\n[color=#70c080]疑云值 -10。[/color]" % extra
		"nova":
			kn.suspicion = clampi(kn.suspicion - 5, 0, 100)
			gs.add_doubt(-10, "公开考验“成功”")
			gs.add_event_note("第3天骑士团的公开考验中，勇者一剑劈断了木桩（虽然圣剑没有发光）。")
			npcs.thief_nova.flags.helped_test = true
			gs.flags.test_passed = true
			gs.log_journal("公开考验：诺娃动了手脚，“通过”。")
			emo = "skeptical"
			text = "你一剑劈下，木桩“咔嚓”一声断成两截，比你想象的还要轻松。\n\n人群欢呼起来。远处屋顶上，有个人影冲你比了个手势，一闪就不见了。\n\n莱恩哈特走过去，蹲下来看了看断口，什么也没说。\n\n[color=#70c080]疑云值 -10。但莱恩哈特似乎看出了什么。[/color]"
		"knight":
			kn.trust = clampi(kn.trust + 5, 0, 100)
			gs.add_doubt(-15, "公开考验“成功”")
			gs.add_event_note("第3天骑士团的公开考验中，勇者劈开了木桩，莱恩哈特当众向勇者行了骑士礼。")
			gs.log_journal("公开考验：和莱恩哈特演完了这场戏。")
			gs.flags.test_passed = true
			emo = "happy"
			text = "木桩是莱恩哈特亲自准备的——昨晚他已经让人把芯子掏空了。\n\n你一剑下去，木桩应声而断。莱恩哈特单膝跪地，当着所有骑士的面向你行了骑士礼。\n\n起身时，他低声说：“演完这场，你欠我三百条命。别让我后悔。”\n\n[color=#70c080]疑云值 -15。[/color]"
		_:
			kn.suspicion = clampi(kn.suspicion + 10, 0, 100)
			kn.trust = clampi(kn.trust - 5, 0, 100)
			gs.add_doubt(8, "拒绝了公开考验")
			gs.add_event_note("第3天骑士团的公开考验中，勇者拒绝出剑，说神力不是用来表演的。")
			gs.log_journal("公开考验：拒绝了。")
			emo = "angry"
			text = "“神力不是用来给人表演的。”\n\n你把剑插回鞘里。人群里响起一阵窃窃私语。\n\n莱恩哈特冷笑一声：“好一个不表演。那到了北境，你也打算这么跟魔王说？”\n\n[color=#e06060]疑云值 +8。莱恩哈特更加怀疑你了。[/color]"
	for n in [kn, mia, sch]:
		n.stance = DialogueRules.compute_stance(n)
	return [{"title": "考验的结果", "portrait": "knight_reinhardt", "emotion": emo, "scene": "training", "text": text}]


static func sermon_interrogation_intro() -> Array:
	return [{"title": "第 5 天 · 上午　布道大会", "portrait": "priest_seraphim", "emotion": "skeptical", "scene": "temple", "tint": Color(0.75, 0.75, 0.9),
		"text": "布道大会上，广场上的人比仪式那天还多。但这一次，你听见的不只是欢呼。\n\n“听说他连木桩都劈不开……”\n“米娅说他能召唤雷电，可骑士团的人说……”\n\n布道结束后，大祭司把你叫进了偏厅。几位高阶祭司站在他身后，没有人说话。\n\n[color=#e06060]王都的疑云值已经很高了。这是一次审问。[/color]"}]


static func sermon_calm() -> Array:
	GameState.add_doubt(-5, "布道大会")
	return [{"title": "第 5 天 · 上午　布道大会", "portrait": "priest_seraphim", "emotion": "happy", "scene": "temple",
		"text": "布道大会顺利结束。大祭司在讲坛上把你夸成了“神恩的化身”，人群一次次高呼你的名字。\n\n散场时，他远远地朝你点了点头。那个眼神的意思很清楚：[color=#e0b040]继续这样演下去。[/color]\n\n[color=#70c080]疑云值 -5。[/color]"}]


static func nova_visit_intro() -> Array:
	return [{"title": "第 6 天 · 夜晚　不速之客", "portrait": "thief_nova", "emotion": "happy", "scene": "map", "tint": NIGHT_TINT,
		"text": "你正准备吹灯，窗户“咔哒”一声开了。\n\n一个披着斗篷的年轻女人蹲在窗台上，冲你晃了晃手里的匕首——不是威胁，更像是打招呼。\n\n[color=#e0b040]“晚上好啊，大英雄。我叫诺娃。仪式前一晚，我刚好在神殿里‘散步’。你想不想知道我看见了什么？”[/color]"}]


static func feast_intro() -> Array:
	return [{"title": "第 7 天 · 夜晚　出征前夜宴", "portrait": "king", "emotion": "happy", "bg": Color("#1d140c"),
		"text": "王宫的宴会厅灯火通明。国王举杯祝你凯旋，贵族们轮流上前和你碰杯。\n\n明天清晨就要出征了。这是最后一次和别人好好说话的机会。\n\n你环顾四周——他们都在这里。"}]


static func feast_choices() -> Array:
	var res: Array = []
	for id in GameState.npcs:
		var n: NpcState = GameState.npcs[id]
		if id == "thief_nova":
			res.append({"id": id, "label": "溜到阳台上，找混进来的诺娃（%s）" % n.stance})
		else:
			res.append({"id": id, "label": "去找%s（%s）" % [n.display_name(), n.stance]})
	res.append({"id": "sleep", "label": "早点回去休息"})
	return res


static func rumors() -> Array:
	var gs := GameState
	var lines := PackedStringArray()
	lines.append("酒馆里人声鼎沸。你压低帽檐，在角落里坐了一会儿。\n")
	lines.append("[color=#e0b040]王都的风向：[/color]%s（疑云值 %d）\n" % [DialogueRules.doubt_desc(gs.doubt), gs.doubt])
	var heard: Array = []
	for id in gs.npcs:
		var n: NpcState = gs.npcs[id]
		for h in n.heard_claims:
			heard.append("有人说，勇者对%s讲过：“%s”" % [h.from, h.text])
	if heard.size() > 0:
		lines.append("[color=#e0b040]你听见的议论：[/color]")
		heard.shuffle()
		for h in heard.slice(0, 4):
			lines.append("· " + h)
	else:
		lines.append("· 人们大多在聊魔王军和粮价，暂时没什么关于你的新说法。")
	var hostile := PackedStringArray()
	var friendly := PackedStringArray()
	for id in gs.npcs:
		var n: NpcState = gs.npcs[id]
		if n.is_antagonist():
			continue
		if n.stance in ["敌对", "试探"]:
			hostile.append(n.display_name())
		elif n.stance in ["合作", "崇拜", "共犯"]:
			friendly.append(n.display_name())
	lines.append("")
	if hostile.size() > 0:
		lines.append("[color=#e06060]据说%s对你颇有微词。[/color]" % "、".join(hostile))
	if friendly.size() > 0:
		lines.append("[color=#70c080]也有人说%s在替你说话。[/color]" % "、".join(friendly))
	return [{"title": "金麦酒馆　打听流言", "portrait": "tavern_keeper", "emotion": "neutral", "scene": "tavern", "text": "\n".join(lines)}]


static func investigate_altar() -> Array:
	var gs := GameState
	gs.flags.investigated_altar = true
	var nova: NpcState = gs.npcs.thief_nova
	var helped := bool(nova.flags.get("promised_help", false)) or nova.is_accomplice() or nova.is_joined()
	gs.player_learn("F_SWORD_DEVICE")
	if helped:
		gs.flags.has_device_evidence = true
		GoalSystem.give_card(gs, "C_DEVICE_PART")
		gs.log_journal("和诺娃一起潜入正殿，拿到了发光装置的零件。")
		return [{"title": "深夜的正殿", "portrait": "thief_nova", "emotion": "happy", "bg": NIGHT_BG, "cg": "device",
			"text": "诺娃两下就撬开了侧门的锁，替你在外面望风。\n\n剑座底下有一块松动的石板。掀开之后，里面是一团缠满符文铜线的魔导装置，正发出微弱的嗡鸣。\n\n你拆下了一枚刻着神殿徽记的符文核心，揣进怀里。\n\n[color=#70c080]你得知了「圣剑发光靠魔导装置」，并拿到了实证。[/color]"}]
	var pr: NpcState = gs.npcs.priest_seraphim
	pr.suspicion = clampi(pr.suspicion + 20, 0, 100)
	pr.stance = DialogueRules.compute_stance(pr)
	gs.add_doubt(5, "深夜擅闯正殿")
	gs.log_journal("独自潜入正殿，被巡夜的祭司撞见。")
	return [{"title": "深夜的正殿", "portrait": "priest_seraphim", "emotion": "angry", "bg": NIGHT_BG, "scene": "temple", "tint": NIGHT_TINT,
		"text": "你从侧窗翻进正殿，摸到剑座前。石板下面露出一团缠满铜线的装置——\n\n“谁在那里？”\n\n巡夜祭司的灯笼照了过来。你只来得及看清那东西一眼，就被“请”回了住处。\n\n[color=#e06060]你得知了「圣剑发光靠魔导装置」，但没有拿到实证。大祭司一定会听说这件事。疑云值 +5。[/color]"}]


static func night_report(ended_day: int, lines: Array, changes: Array) -> Array:
	var s := PackedStringArray()
	s.append("[color=#e0b040]今夜的传闻：[/color]")
	for l in lines:
		s.append("· " + str(l))
	s.append("")
	if changes.size() > 0:
		s.append("[color=#e0b040]今天的疑云变化：[/color]")
		for c in changes:
			var d: int = int(c.delta)
			s.append("· %s  [color=%s]%+d[/color]" % [c.reason, "#e06060" if d > 0 else "#70c080", d])
	s.append("疑云值：%d —— %s" % [GameState.doubt, DialogueRules.doubt_desc(GameState.doubt)])
	s.append("")
	if GameState.day <= GameState.LAST_DAY:
		s.append("[color=#a89fb8]已自动存档：第 %d 天早晨。[/color]" % GameState.day)
	return [{"title": "第 %d 天 · 夜幕降临" % ended_day, "portrait": "hero", "emotion": "sad" if GameState.doubt >= 60 else "neutral", "bg": NIGHT_BG, "scene": "map", "tint": NIGHT_TINT, "font": "sans", "text": "\n".join(s)}]


static func final_morning() -> Array:
	var p := EndingRules.check_party(GameState)
	var s := "出征的号角在城门外响起。\n\n"
	s += "讨伐队：%s\n" % ("、".join(p.party) if p.party.size() > 0 else "只有你自己")
	s += "骑士团：%s\n" % ("随行" if p.knight else "[color=#e06060]没有出兵[/color]")
	s += "魔王的弱点：%s\n" % ("已经掌握" if p.weakness else "[color=#e06060]一无所知[/color]")
	s += "疑云值：%d\n\n" % GameState.doubt
	s += "城门就在眼前。"
	if bool(GameState.flags.get("escape_offered", false)):
		s += "\n\n巷口，诺娃靠在墙上冲你挑了挑眉：退路还在。"
	return [{"title": "第 8 天 · 清晨", "portrait": "hero", "emotion": "neutral", "scene": "map", "tint": DAWN_TINT, "font": "sans", "text": s}]


static func final_choices() -> Array:
	var res: Array = [{"id": "march", "label": "走出城门，出征"}]
	var nova: NpcState = GameState.npcs.thief_nova
	if bool(GameState.flags.get("escape_offered", false)) and nova.stance != "敌对":
		res.append({"id": "flee", "label": "转身跟着诺娃离开"})
	return res


static func ending_pages(e: Dictionary) -> Array:
	var gs := GameState
	var summary := PackedStringArray()
	summary.append("[color=#e0b040]结局：%s[/color]（%s）\n" % [e.title, e.tone])
	summary.append("讨伐队：%s" % ("、".join(e.party) if e.party.size() > 0 else "无"))
	var knowers := PackedStringArray()
	for id in gs.npcs:
		var n: NpcState = gs.npcs[id]
		if bool(n.flags.get("knows_truth", false)) and not n.is_antagonist():
			knowers.append("%s（%s）" % [n.display_name(), n.stance])
	summary.append("知道真相的人：%s" % ("、".join(knowers) if knowers.size() > 0 else "无"))
	summary.append("最终疑云值：%d" % gs.doubt)
	summary.append("\n[color=#a89fb8]本 Demo 共有 5 个结局：替罪羊 / 壮烈殉国 / 完美的谎言 / 众人之剑 / 逃兵。[/color]")
	var portrait := "hero"
	var emo := "neutral"
	var cg_id: String = {"flee": "ending_flee", "scapegoat": "ending_scapegoat", "martyr": "ending_martyr",
		"perfect_lie": "ending_lie", "many_swords": "ending_all"}.get(e.key, "")
	match e.key:
		"flee":
			portrait = "thief_nova"
			emo = "happy"
		"scapegoat":
			portrait = "priest_seraphim"
			emo = "happy"
		"martyr":
			emo = "sad"
		"perfect_lie":
			emo = "nervous"
		"many_swords":
			emo = "happy"
	return [
		{"title": "结局 · " + e.title, "portrait": portrait, "emotion": emo, "cg": cg_id, "text": e.text},
		{"title": "回顾", "portrait": "", "emotion": emo, "scene": ("cg:" + cg_id) if cg_id != "" else "map", "font": "sans", "text": "\n".join(summary)},
	]
