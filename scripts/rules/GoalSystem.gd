class_name GoalSystem
extends RefCounted
## 每个角色的“心结”（小目标）、线索卡、加入讨伐队的条件、地图上的“接下来”。
## 全部由代码判定；模型只负责把结果演出来。
##
## 目标条件（data/npcs/*.json 的 goals[].when）：
##   {"any": [...]} / {"all": [...]}
##   {"confessed": true}            向这个人坦白过
##   {"presented": "C_X"}           向这个人出示过某张线索卡
##   {"flag": "test_passed"}        全局标记
##   {"npc_joined": "knight_reinhardt"}
##   {"trust": 75}                  这个人的信任 ≥ 75
##   {"sessions": 2}                和这个人认真谈过（至少说了 2 句）的次数
##   {"player_lines": 1}            对这个人说过的话（总句数）
## 奖励（reward）：cards / facts / npc_flags / global_flags / note

const PRIORITY := ["knight_reinhardt", "scholar_oswald", "thief_nova", "apprentice_mia"]


# ---------------------------------------------------------------- 目标

static func goals(n: NpcState) -> Array:
	return n.def.get("goals", [])


static func visible_goals(n: NpcState) -> Array:
	var res: Array = []
	for g in goals(n):
		if not bool(g.get("hidden", false)):
			res.append(g)
	return res


static func is_done(n: NpcState, gid: String) -> bool:
	return bool(n.flags.get("goal_" + gid, false))


static func next_goal(n: NpcState) -> Dictionary:
	for g in visible_goals(n):
		if not is_done(n, g.id):
			return g
	return {}


static func cond(n: NpcState, c: Dictionary, gs: Node) -> bool:
	if c.has("any"):
		for x in c.any:
			if cond(n, x, gs):
				return true
		return false
	if c.has("all"):
		for x in c.all:
			if not cond(n, x, gs):
				return false
		return true
	if c.has("confessed"):
		return bool(n.flags.get("player_confessed", false))
	if c.has("presented"):
		return (n.flags.get("presented", []) as Array).has(c.presented)
	if c.has("flag"):
		return bool(gs.flags.get(c.flag, false))
	if c.has("npc_joined"):
		var o: NpcState = gs.npcs.get(c.npc_joined)
		return o != null and o.is_joined()
	if c.has("trust"):
		return n.trust >= int(c.trust)
	if c.has("sessions"):
		return int(n.flags.get("sessions", 0)) >= int(c.sessions)
	if c.has("player_lines"):
		var cnt := 0
		for e in n.transcript:
			if e.get("who") == "player":
				cnt += 1
		return cnt >= int(c.player_lines)
	return false


## 检查所有角色的目标（条件可能互相牵连），返回给玩家看的提示。
static func check_all(gs: Node) -> Array:
	var notes: Array = []
	for _pass in 2:
		for id in gs.npcs:
			notes.append_array(check(gs.npcs[id], gs))
	return notes


static func check(n: NpcState, gs: Node) -> Array:
	var notes: Array = []
	for g in goals(n):
		if is_done(n, g.id):
			continue
		if not cond(n, g.get("when", {}), gs):
			continue
		n.flags["goal_" + g.id] = true
		if not bool(g.get("hidden", false)):
			notes.append("★ 目标完成：%s · %s" % [n.display_name(), g.title])
			gs.log_journal("%s：%s（完成）" % [n.display_name(), g.title])
		var r: Dictionary = g.get("reward", {})
		if r.has("note"):
			notes.append("✦ " + str(r.note))
		for f in r.get("facts", []):
			gs.player_learn(str(f))
			n.learn(str(f))
		for k in r.get("npc_flags", {}):
			n.flags[k] = r.npc_flags[k]
		for k in r.get("global_flags", {}):
			gs.flags[k] = r.global_flags[k]
		for c in r.get("cards", []):
			if give_card(gs, str(c)):
				notes.append("◈ 获得线索：「%s」" % card_name(str(c)))
	if not notes.is_empty() and can_join(n):
		notes.append("➜ %s 的心结都解开了：现在可以邀请%s加入讨伐队。" % [n.display_name(), "她" if _is_female(n) else "他"])
	return notes


static func _is_female(n: NpcState) -> bool:
	return n.id in ["apprentice_mia", "thief_nova"]


static func pronoun(n: NpcState) -> String:
	return "她" if _is_female(n) else "他"


# ---------------------------------------------------------------- 加入讨伐队

static func can_join(n: NpcState) -> bool:
	if n.is_antagonist() or n.stance == "敌对" or n.is_joined():
		return false
	for g in visible_goals(n):
		if not is_done(n, g.id):
			return false
	return true


static func missing_views(n: NpcState) -> String:
	var res := PackedStringArray()
	for g in visible_goals(n):
		if not is_done(n, g.id):
			res.append(str(g.get("npc_view", g.title)))
	if n.stance == "敌对":
		res.append("你认定勇者是骗子，根本不想和他共事。")
	return " ".join(res)


## 写进提示词：这个角色心里在等什么
static func npc_mind(n: NpcState) -> String:
	if n.is_antagonist():
		return ""
	if n.is_joined():
		return "你已经答应加入讨伐队，和勇者站在一边了。"
	var g := next_goal(n)
	if g.is_empty():
		return "你对勇者已经没有心结了。如果他请你加入讨伐队，你会答应。"
	return str(g.get("npc_view", ""))


# ---------------------------------------------------------------- 线索卡

static func clue(id: String) -> Dictionary:
	return GameState.clues.get(id, {})


static func card_name(id: String) -> String:
	return str(clue(id).get("name", id))


static func give_card(gs: Node, id: String) -> bool:
	if gs.cards.has(id) or not gs.clues.has(id):
		return false
	gs.cards.append(id)
	gs.log_journal("获得线索「%s」" % card_name(id))
	return true


## 出示某张卡给某个人的效果（不修改状态）
static func present_effect(id: String, n: NpcState) -> Dictionary:
	var op: Dictionary = clue(id).get("on_present", {})
	var e: Dictionary = op.get(n.id, op.get("*", {}))
	if e.is_empty():
		e = {"reaction": "勇者给你看了这个。你不太明白他的用意。"}
	return e


static func apply_present(gs: Node, id: String, n: NpcState) -> Dictionary:
	## 返回 {before}，并修改数值 / 记录出示
	var e := present_effect(id, n)
	n.trust = clampi(n.trust + int(e.get("trust", 0)), 0, 100)
	n.suspicion = clampi(n.suspicion + int(e.get("suspicion", 0)), 0, 100)
	n.affinity = clampi(n.affinity + int(e.get("affinity", 0)), -100, 100)
	var arr: Array = n.flags.get("presented", [])
	if not arr.has(id):
		arr.append(id)
	n.flags.presented = arr
	if bool(e.get("consume", false)):
		gs.cards.erase(id)
	return e


# ---------------------------------------------------------------- 档案

## 档案逐步解锁：传闻一开始就知道；见过面后知道“想要 / 讨厌”；认真谈过一次后知道“喜欢”。
static func dossier_lines(n: NpcState) -> Array:
	var d: Dictionary = n.def.get("dossier", {})
	var res: Array = []
	var met := bool(n.flags.get("met", false))
	var sessions := int(n.flags.get("sessions", 0))
	if d.has("rumor"):
		res.append(["传闻", str(d.rumor)])
	if d.has("wants"):
		res.append(["想要", str(d.wants) if met else "（见过面才知道）"])
	if d.has("dislikes"):
		res.append(["讨厌", str(d.dislikes) if met else "（见过面才知道）"])
	if d.has("likes"):
		res.append(["喜欢", str(d.likes) if sessions >= 1 else "（认真聊过一次才知道）"])
	return res


static func where_text(n: NpcState, gs: Node) -> String:
	var sd: Dictionary = n.def.get("schedule", {})
	var key: String = gs.SLOT_KEYS[clampi(gs.slot, 0, 3)]
	var now = sd.get(key)
	if now != null and not gs.is_feast():
		return "现在在%s" % gs.locations[now].name
	var by_loc := {}
	var order: Array = []
	for i in 4:
		var loc = sd.get(gs.SLOT_KEYS[i])
		if loc == null:
			continue
		if not by_loc.has(loc):
			by_loc[loc] = []
			order.append(loc)
		by_loc[loc].append(gs.SLOTS[i])
	var parts := PackedStringArray()
	for loc in order:
		parts.append("%s在%s" % ["/".join(by_loc[loc]), gs.locations[loc].name])
	return "，".join(parts)


# ---------------------------------------------------------------- 接下来（地图上的任务面板）

## 返回 [{text, sub, kind}]，kind: event / party / npc / done
static func quest_lines(gs: Node, limit: int = 4) -> Array:
	var res: Array = []
	var ev := _upcoming_event(gs)
	if not ev.is_empty():
		res.append(ev)
	var npc_lines: Array = []
	for id in PRIORITY:
		var n: NpcState = gs.npcs[id]
		if n.is_joined():
			continue
		if n.stance == "敌对":
			npc_lines.append({"kind": "npc", "id": id, "text": "%s已经和你翻脸了" % n.display_name(), "sub": "也许坦白，或者拿出实证，还能挽回。"})
			continue
		if can_join(n):
			npc_lines.append({"kind": "npc", "id": id, "text": "邀请%s加入讨伐队" % n.display_name(), "sub": "%s的心结都解开了。" % n.display_name(), "where": where_text(n, gs)})
			continue
		var g := next_goal(n)
		if g.is_empty():
			continue
		npc_lines.append({"kind": "npc", "id": id, "text": "%s：%s" % [n.display_name(), g.title], "sub": str(g.hint), "where": where_text(n, gs)})
	res.append_array(npc_lines)
	var p := EndingRules.check_party(gs)
	if p.knight and p.weakness and p.party.size() >= 2:
		res.push_front({"kind": "done", "text": "讨伐队已经凑齐，可以出征了", "sub": "还有时间的话，可以继续争取别人，或者把真相告诉更多同伴。"})
	return res.slice(0, limit)


static func _upcoming_event(gs: Node) -> Dictionary:
	var d: int = gs.day
	var s: int = gs.slot
	if d == 1:
		return {"kind": "event", "text": "明天上午：大祭司要召见你", "sub": "他想确认你会不会“乖乖听话”。"}
	if d == 2 or (d == 3 and s <= 0):
		var when := "明天下午" if d == 2 else "今天下午"
		return {"kind": "event", "text": "%s：骑士团的公开考验" % when, "sub": "你劈不开包铁的木桩。提前找米娅或诺娃帮忙，或者向莱恩哈特坦白。"}
	if d == 4 or (d == 5 and s <= 0):
		return {"kind": "event", "text": ("明天上午" if d == 4 else "今天上午") + "：神殿布道大会", "sub": "疑云值 ≥ 60 时会变成审问（现在 %d）。" % gs.doubt}
	if d == 6:
		return {"kind": "event", "text": "明天夜里：出征前夜宴", "sub": "最后一次和大家好好说话的机会。"}
	if d == 7:
		return {"kind": "event", "text": "今晚：出征前夜宴；明天清晨出征", "sub": "出征前，确认讨伐队已经凑齐。"}
	return {}
