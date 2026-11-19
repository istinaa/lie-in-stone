class_name GossipSystem
extends RefCounted
## 夜间传话：按 NPC 关系图搬运当天的谎言台账，并处理“藏不住的真相”。
## 不调用 LLM，全部由代码完成。返回给夜间过场看的文字。

const MIA_DISTORT := [
	"（米娅转述，听起来比原话夸张了不少）",
	"（米娅讲得眉飞色舞，细节大概添油加醋了）",
]


static func run_night(gs: Node) -> Array:
	var lines: Array = []
	var npcs: Dictionary = gs.npcs
	# 1. 搬运勇者的声明
	for src_id in npcs:
		var src: NpcState = npcs[src_id]
		var targets: Array = src.def.get("gossip_to", [])
		# 共犯会替勇者保守和真相有关的话，但仍会转述其他声明
		for c in src.player_claims:
			if bool(c.get("spread", false)):
				continue
			c.spread = true
			if targets.is_empty():
				continue
			var text: String = str(c.text)
			if src_id == "apprentice_mia" and randf() < 0.5:
				text += MIA_DISTORT.pick_random()
			var told: Array = []
			for t_id in targets:
				if not npcs.has(t_id):
					continue
				var t: NpcState = npcs[t_id]
				t.heard_claims.append({"text": text, "from": src.display_name(), "day": c.get("day", gs.day)})
				if t.heard_claims.size() > 20:
					t.heard_claims = t.heard_claims.slice(t.heard_claims.size() - 20)
				told.append(t.display_name())
			if not told.is_empty():
				lines.append("%s 把你说的「%s」告诉了 %s。" % [src.display_name(), str(c.text), "、".join(told)])

	# 2. 真相的泄露
	var mia: NpcState = npcs.get("apprentice_mia")
	if mia and mia.knows("F_PLAYER_NO_POWER") and not mia.is_accomplice() and not bool(mia.flags.get("leaked", false)):
		mia.flags.leaked = true
		for t_id in mia.def.get("gossip_to", []):
			var t: NpcState = npcs[t_id]
			t.learn("F_PLAYER_NO_POWER")
			t.flags.knows_truth = true
			t.stance = DialogueRules.compute_stance(t)
		gs.add_doubt(20, "米娅哭着把“勇者没有神力”说了出去")
		lines.append("米娅没能守住秘密。她哭着把“勇者没有神力”告诉了好几个人。")

	for id in npcs:
		var n: NpcState = npcs[id]
		if n.is_antagonist() or id == "apprentice_mia":
			continue
		if n.knows("F_PLAYER_NO_POWER") and n.stance == "敌对" and not bool(n.flags.get("reported", false)):
			n.flags.reported = true
			gs.add_doubt(12, "%s 向神殿告发了你" % n.display_name())
			var priest: NpcState = npcs.get("priest_seraphim")
			if priest:
				priest.suspicion = clampi(priest.suspicion + 20, 0, 100)
				priest.stance = DialogueRules.compute_stance(priest)
			lines.append("%s 认定你是骗子，去神殿告发了你。" % n.display_name())

	# 3. 学者和骑士会交换对矛盾的看法
	var sch: NpcState = npcs.get("scholar_oswald")
	var kn: NpcState = npcs.get("knight_reinhardt")
	if sch and kn and sch.contradictions.size() > 0 and not sch.is_accomplice():
		var last: Dictionary = sch.contradictions[-1]
		if int(last.get("day", 0)) == gs.day:
			kn.suspicion = clampi(kn.suspicion + 5, 0, 100)
			kn.stance = DialogueRules.compute_stance(kn)
			lines.append("奥斯瓦德和莱恩哈特在酒馆聊起了你话里的矛盾。")

	# 4. 神殿的眼线：米娅转述的话也会传到大祭司耳中
	var pr: NpcState = npcs.get("priest_seraphim")
	if pr:
		var confessed_to: Array = gs.flags.get("confessed_to", [])
		if confessed_to.size() > 0 and not bool(pr.flags.get("heard_confession", false)):
			# 坦白的消息早晚会传到大祭司那里（除非对方都是共犯）
			var leaky := false
			for cid in confessed_to:
				var cn: NpcState = npcs.get(cid)
				if cn and not cn.is_accomplice() and not cn.is_antagonist():
					leaky = true
			if leaky:
				pr.flags.heard_confession = true
				pr.suspicion = clampi(pr.suspicion + 25, 0, 100)
				lines.append("神殿的眼线听说，勇者私下里说了些“不该说的话”。")

	if lines.is_empty():
		lines.append("今晚的王都很安静，没有什么关于你的新传闻。")
	return lines
