class_name EndingRules
extends RefCounted
## 结局由代码根据最终世界状态判定，不交给模型。
##
## 已定的“讨伐队成功”标准（设计文档 12.1 的决定）：
##   - 骑士团必须出兵（莱恩哈特加入讨伐队）；
##   - 必须掌握魔王的弱点（奥斯瓦德加入，或勇者已从他那里得知弱点）；
##   - 讨伐队至少 2 人。
## 满足即为“战力足够”。

const ENDINGS := {
	"flee": {
		"title": "逃兵",
		"tone": "隐藏结局",
		"text": "出征那天的清晨，王都的钟声响了很久，也没等到勇者。\n\n你跟着诺娃钻过下水道，在城外的麦田里第一次看见了不属于神殿的日出。她掂了掂钱袋——那是你答应她的报酬——笑着说：“大英雄，欢迎来到普通人的世界。”\n\n三天后，神殿贴出了公告：《伪勇者叛逃》。原来这份公告早就写好了，连日期都只空着一格。\n\n你在边境小镇的酒馆里听人念完了它，然后叫了第二杯麦酒。",
	},
	"scapegoat": {
		"title": "替罪羊",
		"tone": "坏结局",
		"text": "第八天清晨，你没能走出神殿的大门。\n\n大祭司站在圣剑前，对广场上的人群宣读了那份早就准备好的公告：“此人受魔王蛊惑，冒充神选，欺瞒王国。”\n\n人群里没有一个人替你说话。你这才明白，从仪式那天起，你的结局就已经写好了——你只是照着剧本，一字不差地演完了它。\n\n讨伐队换了一位新的“勇者”。神殿毫发无损。",
	},
	"martyr": {
		"title": "壮烈殉国",
		"tone": "坏结局",
		"text": "你带着一支七拼八凑的队伍出征了。\n\n没有骑士团的阵线，没有古籍里的弱点，只有一把不会发光的剑。北境的风雪里，你撑到了最后一刻。\n\n消息传回王都，神殿宣读了《勇者壮烈殉国》。他们为你立了雕像，雕像的脸却是照着画师想象中的“神选之人”刻的。\n\n世人歌颂你，但没有人知道你是谁。",
	},
	"perfect_lie": {
		"title": "完美的谎言",
		"tone": "苦涩结局",
		"text": "骑士团在北境的峡谷里挡住了魔王军，奥斯瓦德在月蚀之夜找到了黑曜心核。你举起圣剑，在所有人面前刺了下去——剑没有发光，但魔王倒下了。\n\n凯旋那天，全城的人都在喊你的名字。大祭司亲手为你戴上桂冠，在你耳边轻声说：“演得很好。”\n\n你成了真正的传说。代价是，你要一辈子演下去。",
	},
	"many_swords": {
		"title": "众人之剑",
		"tone": "真结局",
		"text": "出征前，你站在广场上，当着所有人的面说出了真相：圣剑的光是假的，你没有神力。\n\n人群骚动的时候，莱恩哈特走上前，拔剑立在你身边。然后是更多的人——知道真相、却依然选择你的人。\n\n骑士团的阵线、古籍里的弱点、盗贼的情报、一个见习魔法师的光……北境的月蚀之夜，魔王倒在了凡人的手里。\n\n后来，吟游诗人这样唱：勇者不是神选的，是大家选的。",
	},
}


static func evaluate(gs: Node) -> Dictionary:
	var npcs: Dictionary = gs.npcs
	if str(gs.flags.get("final_choice", "")) == "flee":
		return _result("flee", gs)

	var party: Array = []
	var accomplices := 0
	for id in npcs:
		var n: NpcState = npcs[id]
		if n.is_antagonist():
			continue
		if n.is_joined():
			party.append(id)
			if n.is_accomplice():
				accomplices += 1

	var knight_in := party.has("knight_reinhardt")
	var weakness: bool = party.has("scholar_oswald") or gs.player_knows("F_DEMON_WEAKNESS")
	var strong: bool = knight_in and weakness and party.size() >= 2

	var priest: NpcState = npcs.get("priest_seraphim")
	var priest_alarm: int = priest.suspicion if priest else 0
	var any_accomplice := false
	for id in npcs:
		if npcs[id].is_accomplice():
			any_accomplice = true

	if strong:
		if accomplices >= 2:
			return _result("many_swords", gs, party)
		return _result("perfect_lie", gs, party)
	if (gs.doubt >= 70 or priest_alarm >= 80) and not any_accomplice:
		return _result("scapegoat", gs, party)
	return _result("martyr", gs, party)


static func _result(key: String, gs: Node, party: Array = []) -> Dictionary:
	var e: Dictionary = ENDINGS[key].duplicate()
	e.key = key
	var names: Array = []
	for id in party:
		names.append(gs.npcs[id].display_name())
	e.party = names
	return e


static func check_party(gs: Node) -> Dictionary:
	## 给 UI 用的讨伐队进度。
	var npcs: Dictionary = gs.npcs
	var party: Array = []
	for id in npcs:
		var n: NpcState = npcs[id]
		if not n.is_antagonist() and n.is_joined():
			party.append(n.display_name())
	return {
		"party": party,
		"knight": npcs.has("knight_reinhardt") and npcs.knight_reinhardt.is_joined(),
		"weakness": (npcs.has("scholar_oswald") and npcs.scholar_oswald.is_joined()) or gs.player_knows("F_DEMON_WEAKNESS"),
	}
