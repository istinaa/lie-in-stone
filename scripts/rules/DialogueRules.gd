class_name DialogueRules
extends RefCounted
## 代码掌控的规则：限幅、阶段判定、动作白名单、模型输出校验、状态写入。
## 原则：LLM 只“演”和“提议”，一切写进存档的变化都经过这里。

const DELTA_LIMIT := 15
const EMOTIONS := ["neutral", "happy", "angry", "skeptical", "surprised", "sad", "nervous"]
const TACTICS := ["说服", "表演", "撒谎", "转移", "坦白", "威胁", "交易"]
const MAX_TURNS := 8
const MAX_INPUT_CHARS := 200

const STANCE_DESC := {
	"崇拜": "言听计从，会主动帮勇者宣传",
	"合作": "愿意提供帮助和资源",
	"观望": "正常交流，有所保留",
	"试探": "怀疑勇者，会主动设考验、追问细节",
	"敌对": "认定勇者是骗子，拒绝合作，可能去告发",
	"共犯": "知道勇者没有神力，但仍然愿意站在他这边",
}

const ACTION_DESC := {
	"none": "没有特别的动作",
	"end_conversation": "你决定结束这次谈话（有事要走、或者不想再聊）",
	"refuse": "明确拒绝勇者的请求",
	"propose_test": "要求勇者当场证明神力",
	"promise_help": "答应在骑士团的公开考验（第3天下午）或别的难关中暗中帮勇者一把",
	"join_party": "郑重答应加入七天后的讨伐队，和勇者一起出征",
	"share_info": "",  # 由 NPC 数据中的 share.desc 填充
	"report_player": "决定去向神殿或骑士团告发勇者是骗子",
	"offer_escape": "提出可以带勇者在出征前夜偷偷逃出王都（要价不菲）",
	"warn_player": "以神殿的名义警告勇者别轻举妄动",
}


static func compute_stance(n: NpcState) -> String:
	if bool(n.flags.get("knows_truth", false)) and n.trust > 50 and not n.is_antagonist():
		return "共犯"
	if n.suspicion > 85 and n.trust < 20:
		return "敌对"
	if n.trust > 80 and n.suspicion < 20:
		return "崇拜"
	if n.trust > 50:
		return "合作"
	if n.suspicion > 60:
		return "试探"
	return "观望"


static func allowed_actions(n: NpcState) -> Array:
	var acts := ["none", "end_conversation"]
	if n.is_antagonist():
		acts.append_array(["refuse", "warn_player"])
		return acts
	match n.stance:
		"敌对":
			acts.append_array(["refuse", "report_player"])
		"试探", "观望":
			acts.append_array(["refuse", "propose_test"])
		"合作", "崇拜", "共犯":
			acts.append_array(["refuse", "promise_help"])
	# 加入讨伐队由代码判定：心结都解开了才允许
	if GoalSystem.can_join(n):
		acts.append("join_party")
	var share = n.def.get("share")
	if share is Dictionary and n.stance != "敌对" and not bool(n.flags.get("shared", false)) \
			and n.trust >= int(share.get("min_trust", 60)):
		acts.append("share_info")
	if bool(n.def.get("can_offer_escape", false)) and n.stance != "敌对" and n.trust >= 55:
		acts.append("offer_escape")
	return acts


static func action_desc(n: NpcState, action: String) -> String:
	if action == "share_info":
		var share = n.def.get("share")
		return str(share.get("desc", "")) if share is Dictionary else ""
	return ACTION_DESC.get(action, "")


static func can_offer_confession(n: NpcState) -> bool:
	## 只有满足条件时才推荐“坦白”，避免玩家随手点错做出不可撤回的决定。
	if bool(n.flags.get("knows_truth", false)) and n.is_antagonist():
		return false
	if bool(n.flags.get("player_confessed", false)):
		return false
	return n.trust >= 40 or n.suspicion >= 80


static func _truthy(v) -> bool:
	## 模型可能给 true / 1 / "true"，统一处理，避免 int 与 bool 直接比较报错。
	match typeof(v):
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return v != 0
		TYPE_STRING:
			return v.strip_edges().to_lower() in ["true", "1", "yes", "是"]
	return false


static func clampi_delta(v) -> int:
	return clampi(int(v) if (v is int or v is float) else 0, -DELTA_LIMIT, DELTA_LIMIT)


static func sanitize(raw: Dictionary, n: NpcState, player_known: Array) -> Dictionary:
	## 校验模型输出，返回干净的结构；reply 缺失视为无效（返回空字典）。
	var reply := str(raw.get("reply", "")).strip_edges()
	if reply.is_empty():
		return {}
	var out := {}
	out.reply = reply.left(400)
	var emo := str(raw.get("emotion", "neutral")).strip_edges().to_lower()
	out.emotion = emo if EMOTIONS.has(emo) else "neutral"
	out.impression = str(raw.get("impression", "")).strip_edges().left(30)
	var act := str(raw.get("action", "none")).strip_edges()
	out.action = act if allowed_actions(n).has(act) else "none"
	out.trust_delta = clampi_delta(raw.get("trust_delta", 0))
	out.suspicion_delta = clampi_delta(raw.get("suspicion_delta", 0))
	out.affinity_delta = clampi_delta(raw.get("affinity_delta", 0))
	var claims: Array = []
	if raw.get("player_claims") is Array:
		for c in raw.player_claims:
			if c is Dictionary and str(c.get("text", "")).strip_edges() != "":
				claims.append({"text": str(c.text).left(60), "topic": str(c.get("topic", "other"))})
	out.player_claims = claims.slice(0, 3)
	out.player_confessed = _truthy(raw.get("player_confessed", false))
	var facts: Array = []
	if raw.get("player_revealed_facts") is Array:
		for f in raw.player_revealed_facts:
			if player_known.has(str(f)) and not facts.has(str(f)):
				facts.append(str(f))
	out.player_revealed_facts = facts
	var contra = raw.get("noticed_contradiction")
	out.noticed_contradiction = str(contra).left(100) if (contra is String and contra.strip_edges() != "" and contra != "null") else ""
	var sugg: Array = []
	var used := {}
	if raw.get("suggested_replies") is Array:
		for s in raw.suggested_replies:
			if not (s is Dictionary):
				continue
			var tac := str(s.get("tactic", "")).strip_edges()
			var txt := str(s.get("text", "")).strip_edges()
			if txt.is_empty() or not TACTICS.has(tac) or used.has(tac):
				continue
			if tac == "坦白" and not can_offer_confession(n):
				continue
			used[tac] = true
			sugg.append({"tactic": tac, "text": txt.left(60)})
	out.suggested_replies = sugg.slice(0, 3)
	return out


static func apply(n: NpcState, r: Dictionary, gs: Node, player_line: String) -> Array:
	## 把校验后的结果写进状态，返回给玩家看的系统提示（字符串数组）。
	var notes: Array = []
	var day: int = gs.day
	n.trust = clampi(n.trust + r.trust_delta, 0, 100)
	n.suspicion = clampi(n.suspicion + r.suspicion_delta, 0, 100)
	n.affinity = clampi(n.affinity + r.affinity_delta, -100, 100)

	for c in r.player_claims:
		n.player_claims.append({"text": c.text, "topic": c.topic, "day": day, "spread": false})
	if n.player_claims.size() > 30:
		n.player_claims = n.player_claims.slice(n.player_claims.size() - 30)

	if r.noticed_contradiction != "":
		n.contradictions.append({"text": r.noticed_contradiction, "day": day})
		n.suspicion = clampi(n.suspicion + 5, 0, 100)
		notes.append("⚠ %s 注意到了你话里的矛盾：%s" % [n.display_name(), r.noticed_contradiction])

	if r.player_confessed and not bool(n.flags.get("player_confessed", false)):
		n.flags.player_confessed = true
		n.flags.knows_truth = true
		n.flags.confessed_day = day
		n.learn("F_PLAYER_NO_POWER")
		n.learn("F_RITUAL_FAKE")
		# 主动坦白（对方并没有把你逼到墙角）比被拆穿后坦白更有分量
		if n.suspicion < 80 and not n.is_antagonist():
			n.trust = clampi(n.trust + 5, 0, 100)
		n.suspicion = 100
		notes.append("✦ 你向 %s 坦白了：你没有神力。这无法撤回。" % n.display_name())
		gs.on_confession(n)

	for f in r.player_revealed_facts:
		if n.learn(f):
			notes.append("✦ %s 从你这里得知：%s" % [n.display_name(), gs.fact_short(f)])
			if f == "F_PLAYER_NO_POWER":
				n.flags.knows_truth = true

	match r.action:
		"join_party":
			if not bool(n.flags.get("joined", false)):
				n.flags.joined = true
				notes.append("★ %s 答应加入讨伐队！" % n.display_name())
		"promise_help":
			if not bool(n.flags.get("promised_help", false)):
				n.flags.promised_help = true
				notes.append("★ %s 答应在关键时刻暗中帮你。" % n.display_name())
		"share_info":
			var share = n.def.get("share")
			if share is Dictionary:
				n.flags.shared = true
				var facts: Array = share.get("facts", [share.get("fact", "")])
				for f in facts:
					if gs.player_learn(str(f)):
						notes.append("★ 你得知了：%s" % gs.fact_text(str(f)))
		"report_player":
			if not bool(n.flags.get("reported", false)):
				n.flags.reported = true
				gs.add_doubt(10, "%s 去告发了你" % n.display_name())
				notes.append("× %s 决定去告发你。王都的疑云更重了。" % n.display_name())
		"offer_escape":
			if not bool(gs.flags.get("escape_offered", false)):
				gs.flags.escape_offered = true
				notes.append("★ %s 给了你一条退路：出征那天清晨，可以选择跟她逃走。" % n.display_name())
		"propose_test":
			n.flags.wants_test = true
		"refuse":
			n.flags.refused_count = int(n.flags.get("refused_count", 0)) + 1

	var old := n.stance
	n.stance = compute_stance(n)
	if old != n.stance:
		notes.append("◆ %s 对你的态度变成了「%s」" % [n.display_name(), n.stance])
		if n.stance == "敌对" and not n.is_antagonist():
			n.flags.joined = false
	notes.append_array(GoalSystem.check_all(gs))
	return notes


static func doubt_desc(doubt: int) -> String:
	if doubt < 25:
		return "民众热烈拥戴勇者"
	if doubt < 50:
		return "有零星的风言风语"
	if doubt < 70:
		return "关于“勇者是假的”的流言正在扩散"
	if doubt < 85:
		return "王都人心惶惶，很多人公开质疑勇者"
	return "疑云密布，神殿随时可能宣布勇者是伪勇者"
