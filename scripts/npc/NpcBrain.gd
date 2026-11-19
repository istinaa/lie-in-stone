class_name NpcBrain
extends RefCounted
## PromptBuilder + ResponseParser：
## 拼提示词 → 调 LlmClient → 解析/重试 → 交给 DialogueRules 校验和写入。

const HISTORY_LINES := 12
const SPECIAL_LOCATION_FEAST := "王宫宴会厅（出征前夜宴）"


static func build_system_prompt(n: NpcState) -> String:
	## 固定部分：世界规则 + 人设 + 输出格式。同一个 NPC 每轮都完全一样，便于服务端缓存。
	var d := n.def
	var special := ""
	if d.has("special_meters"):
		special = "【数值含义】" + str(d.special_meters)
	return GameState.prompt_npc_system.format({
		"name": d.name,
		"title": d.title,
		"personality": d.personality,
		"speech_style": d.speech_style,
		"examples": " / ".join(d.get("examples", [])),
		"motivation": d.motivation,
		"secret": d.get("secret", "无"),
		"confession_hint": d.get("confession_hint", ""),
		"special_meters": special,
	})


static func build_state_prompt(n: NpcState, turn: int, player_line: String, location_name: String, special: Dictionary = {}) -> String:
	var gs := GameState
	var p := PackedStringArray()
	p.append("【当前时间】第%d天%s（离出征还有%d天），地点：%s" % [gs.day, gs.slot_name(), max(gs.days_left(), 0), location_name])

	var known := PackedStringArray()
	for f in n.known_facts:
		known.append("- " + gs.fact_text(f))
	p.append("【你知道的内幕】\n" + ("\n".join(known) if known.size() > 0 else "- 无。你相信公开的说法：勇者是被圣剑选中的、身负神力的人。"))

	var revealable := PackedStringArray()
	for f in gs.player_facts:
		if not n.knows(f):
			revealable.append("- %s：%s" % [f, gs.fact_text(f)])
	p.append("【勇者可能透露的内幕】（只有勇者明确说出来时才算你知道了）\n" + ("\n".join(revealable) if revealable.size() > 0 else "- 无"))

	p.append("【你对勇者的当前看法】信任 %d/100，怀疑（认为他是假勇者的程度）%d/100，个人好感 %d（-100~100），态度阶段：%s（%s）" % [
		n.trust, n.suspicion, n.affinity, n.stance, DialogueRules.STANCE_DESC.get(n.stance, "")])
	if bool(n.flags.get("joined", false)):
		p.append("【你的承诺】你已经答应加入讨伐队。")
	if bool(n.flags.get("promised_help", false)):
		p.append("【你的承诺】你已经答应在关键时刻暗中帮勇者。")
	if bool(n.flags.get("player_confessed", false)):
		p.append("【重要】勇者曾在第%d天亲口向你坦白：他没有神力。" % int(n.flags.get("confessed_day", gs.day)))
	var mind := GoalSystem.npc_mind(n)
	if mind != "":
		p.append("【你心里的盘算】%s（这是你此刻最在意的事。谈话中可以自然地流露出来，让勇者明白你在等什么，但不要像念任务一样直说。）" % mind)

	p.append("【你记得的事】" + (n.memory_summary if n.memory_summary != "" else "（这是你们第一次深谈）" if not bool(n.flags.get("met", false)) else "无特别的记忆"))

	var claims := PackedStringArray()
	for c in n.player_claims.slice(max(0, n.player_claims.size() - 10)):
		claims.append("- 第%d天：%s" % [int(c.get("day", 1)), c.text])
	p.append("【勇者之前亲口对你说过的话】\n" + ("\n".join(claims) if claims.size() > 0 else "- 暂无"))

	var heard := PackedStringArray()
	for h in n.heard_claims.slice(max(0, n.heard_claims.size() - 8)):
		heard.append("- 第%d天，%s 说勇者对她/他讲过：%s" % [int(h.get("day", 1)), h.from, h.text])
	if heard.size() > 0:
		p.append("【你从别人那里听来的勇者的说法】（如果和勇者对你说的对不上，你可以当面质问）\n" + "\n".join(heard))
	if n.contradictions.size() > 0:
		var cs := PackedStringArray()
		for c in n.contradictions.slice(max(0, n.contradictions.size() - 3)):
			cs.append("- " + str(c.text))
		p.append("【你之前已经指出过的矛盾】\n" + "\n".join(cs))

	p.append("【王都氛围】疑云值 %d/100：%s" % [gs.doubt, DialogueRules.doubt_desc(gs.doubt)])
	if gs.event_notes.size() > 0:
		p.append("【最近的公共事件】\n- " + "\n- ".join(gs.event_notes))

	var acts := PackedStringArray()
	for a in DialogueRules.allowed_actions(n):
		acts.append("- %s：%s" % [a, DialogueRules.action_desc(n, a)])
	p.append("【可用动作】（action 只能从这里选；只在角色真心这么决定时才用，普通对话填 none）\n" + "\n".join(acts))
	if DialogueRules.can_offer_confession(n):
		p.append("【推荐回复提示】这一轮的 suggested_replies 里可以包含一句“坦白”。")
	else:
		p.append("【推荐回复提示】这一轮的 suggested_replies 里不要出现“坦白”。")

	var hist := PackedStringArray()
	var recent: Array = n.recent_dialogue.slice(max(0, n.recent_dialogue.size() - HISTORY_LINES))
	var last_npc_line := ""
	var cur_day := -1
	for h in recent:
		if int(h.get("day", 1)) != cur_day:
			cur_day = int(h.get("day", 1))
			hist.append("—— 第%d天 ——" % cur_day)
		var who := "勇者" if h.who == "player" else "你（%s）" % n.display_name()
		hist.append("%s：%s" % [who, h.text])
	if not recent.is_empty() and recent[-1].who == "npc" and turn > 0:
		last_npc_line = str(recent[-1].text)
	if hist.size() > 0:
		p.append("【最近的对话】\n" + "\n".join(hist))

	if turn == 0:
		p.append("【本次谈话】勇者刚刚来找你。请你先开口（打招呼、或者直接说出你此刻最想对勇者说的话）。这一轮勇者还没说话：player_claims 为空数组，player_confessed 为 false，各项数值变化为 0。")
		p.append("【勇者这一轮说的话】（勇者走了过来）")
	else:
		var remain := DialogueRules.MAX_TURNS - turn
		var s := "【本次谈话】这是勇者在这次谈话中的第 %d 句（最多 %d 句）。" % [turn, DialogueRules.MAX_TURNS]
		if remain <= 1:
			s += "谈话马上要结束了，请在这一轮自然地收尾（比如“我还有事要忙”），action 可以用 end_conversation。"
		p.append(s)
		var sp := special_prompt(n, special)
		if sp != "":
			p.append(sp)
		if last_npc_line != "":
			p.append("【你刚才说的】" + last_npc_line)
			p.append("【勇者接着对你说】" + player_line)
		else:
			p.append("【勇者这一轮说的话】" + player_line)
	p.append("先在 understanding 里想清楚勇者这句话的意思，再写 reply。请只输出 json。")
	return "\n\n".join(p)


## 出示线索 / 邀请加入：结果由代码决定，这里告诉模型该怎么演。
static func special_prompt(n: NpcState, special: Dictionary) -> String:
	match str(special.get("type", "")):
		"present":
			var id := str(special.card)
			var c := GoalSystem.clue(id)
			var e := GoalSystem.present_effect(id, n)
			var s := "【勇者向你出示了】「%s」（%s）：%s\n【这对你意味着什么】%s" % [c.get("name", id), c.get("type", ""), c.get("desc", ""), e.get("reaction", "")]
			var follow := preview_present(n, id)
			if follow != "":
				s += "\n【随之而来】这件事解开了你的心结。接下来发生的事，请在台词里自然地演出来：" + follow
			s += "\n（数值变化由系统处理：trust_delta、suspicion_delta、affinity_delta 都填 0。）"
			return s
		"invite":
			if GoalSystem.can_join(n):
				return "【勇者正式邀请你加入讨伐队】\n【系统判定】你已经下定决心答应。用你自己的方式郑重地答应，action 填 join_party。"
			return "【勇者正式邀请你加入讨伐队】\n【系统判定】你现在还不会答应。用你自己的方式拒绝，并让勇者清楚地听出你还在等什么：%s\naction 填 refuse。" % GoalSystem.missing_views(n)
	return ""


## 预演：出示这张卡会完成哪些目标（不修改状态）
static func preview_present(n: NpcState, id: String) -> String:
	var saved_flags: Dictionary = n.flags.duplicate(true)
	var saved := [n.trust, n.suspicion, n.affinity]
	var e := GoalSystem.present_effect(id, n)
	n.trust = clampi(n.trust + int(e.get("trust", 0)), 0, 100)
	var arr: Array = (n.flags.get("presented", []) as Array).duplicate()
	if not arr.has(id):
		arr.append(id)
	n.flags.presented = arr
	var out := PackedStringArray()
	for g in GoalSystem.visible_goals(n):
		if not GoalSystem.is_done(n, g.id) and GoalSystem.cond(n, g.get("when", {}), GameState):
			var r: Dictionary = g.get("reward", {})
			out.append(str(r.get("note", "你对勇者的看法有了实质的改变（%s）。" % g.title)))
	n.flags = saved_flags
	n.trust = saved[0]
	n.suspicion = saved[1]
	n.affinity = saved[2]
	return " ".join(out)


static func run_turn(n: NpcState, turn: int, player_line: String, location_name: String, special: Dictionary = {}) -> Dictionary:
	## 返回 {ok, result(已校验), notes, error_kind, message}
	## special: {type: "present", card} / {type: "invite"}
	## 失败时不修改任何状态。
	var messages := [
		{"role": "system", "content": build_system_prompt(n)},
		{"role": "user", "content": build_state_prompt(n, turn, player_line, location_name, special)},
	]
	var sanitized := {}
	var last_err := {}
	var understanding := ""
	for attempt in 2:
		var res: Dictionary = await LlmClient.chat(messages, true, 1000, 0.8)
		if not res.ok:
			last_err = res
			if LlmClient.error_is_key_problem(res.error_kind):
				break
			continue
		var parsed = LlmClient.parse_json_content(res.content)
		if parsed == null:
			last_err = {"error_kind": "parse", "message": "对方似乎没听清（模型回复格式错误）。"}
			continue
		if parsed is Dictionary:
			understanding = str(parsed.get("understanding", "")).left(200)
		sanitized = DialogueRules.sanitize(parsed, n, GameState.player_facts)
		if sanitized.is_empty():
			last_err = {"error_kind": "parse", "message": "对方似乎没听清（模型回复缺少台词）。"}
			continue
		break
	if sanitized.is_empty():
		return {"ok": false, "error_kind": last_err.get("error_kind", "network"), "message": last_err.get("message", "未知错误")}

	# 开场白：不写入数值和声明
	if turn == 0:
		sanitized.trust_delta = 0
		sanitized.suspicion_delta = 0
		sanitized.affinity_delta = 0
		sanitized.player_claims = []
		sanitized.player_confessed = false
		sanitized.player_revealed_facts = []
		sanitized.noticed_contradiction = ""
		if sanitized.action in ["join_party", "promise_help", "report_player", "share_info", "offer_escape"]:
			sanitized.action = "none"
	else:
		n.recent_dialogue.append({"who": "player", "text": player_line, "day": GameState.day})
		n.record("player", player_line, location_name)
	var before := {"trust": n.trust, "suspicion": n.suspicion, "affinity": n.affinity}
	match str(special.get("type", "")):
		"present":
			# 出示线索：数值按数据表变化，模型给的数值不算
			sanitized.trust_delta = 0
			sanitized.suspicion_delta = 0
			sanitized.affinity_delta = 0
			GoalSystem.apply_present(GameState, str(special.card), n)
			GameState.log_journal("向%s出示了「%s」" % [n.display_name(), GoalSystem.card_name(str(special.card))])
		"invite":
			if GoalSystem.can_join(n):
				sanitized.action = "join_party"
			else:
				sanitized.action = "refuse" if DialogueRules.allowed_actions(n).has("refuse") else "none"
	var notes := DialogueRules.apply(n, sanitized, GameState, player_line)
	n.recent_dialogue.append({"who": "npc", "text": sanitized.reply, "day": GameState.day})
	n.record("npc", sanitized.reply, location_name)
	for note in notes:
		n.record("note", str(note), location_name)
	n.flags.met = true
	n.talked_today = true
	sanitized.before = before
	sanitized.understanding = understanding
	return {"ok": true, "result": sanitized, "notes": notes}


static func compress_memories() -> void:
	## 夜间：对今天聊过、且对话较长的 NPC 做记忆摘要。失败就退化为截断，不阻塞流程。
	for id in GameState.npcs:
		var n: NpcState = GameState.npcs[id]
		if not n.talked_today or n.recent_dialogue.size() <= HISTORY_LINES:
			continue
		var cut := n.recent_dialogue.size() - 6
		var old: Array = n.recent_dialogue.slice(0, cut)
		var lines := PackedStringArray()
		for h in old:
			lines.append("第%d天 %s：%s" % [int(h.get("day", 1)), "勇者" if h.who == "player" else n.display_name(), h.text])
		var messages := [
			{"role": "system", "content": GameState.prompt_summary_system.format({"name": n.display_name()})},
			{"role": "user", "content": "【已有记忆】%s\n\n【需要压缩的对话】\n%s\n\n请输出 json。" % [n.memory_summary if n.memory_summary != "" else "无", "\n".join(lines)]},
		]
		var res: Dictionary = await LlmClient.chat(messages, true, 400, 0.7)
		if res.ok:
			var parsed = LlmClient.parse_json_content(res.content)
			if parsed != null and str(parsed.get("summary", "")).strip_edges() != "":
				n.memory_summary = str(parsed.summary).left(300)
		n.recent_dialogue = n.recent_dialogue.slice(cut)
