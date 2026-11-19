class_name NpcState
extends RefCounted
## 单个 NPC 的运行时状态。人设等静态数据放在 def（来自 data/npcs/*.json），不进存档。

var id: String = ""
var def: Dictionary = {}
var trust: int = 50
var suspicion: int = 50
var affinity: int = 0
var stance: String = "观望"
var known_facts: Array = []          # 事实 ID
var player_claims: Array = []        # [{text, topic, day, spread}] 勇者亲口对他说的话（谎言台账）
var heard_claims: Array = []         # [{text, from, day}] 从别人那里听来的勇者的说法
var contradictions: Array = []       # [{text, day}] 他已经当面指出过的矛盾
var memory_summary: String = ""
var recent_dialogue: Array = []      # [{who: "player"/"npc", text, day}]（给模型看的近期对话，夜里会被压缩）
var transcript: Array = []           # [{who, text, day, slot, loc}] 完整对话记录（给玩家看，不压缩）
var flags: Dictionary = {}           # knows_truth, joined, promised_help, shared, met, reported ...
var talked_today: bool = false


static func from_def(d: Dictionary) -> NpcState:
	var s := NpcState.new()
	s.id = d.id
	s.def = d
	s.trust = int(d.initial.trust)
	s.suspicion = int(d.initial.suspicion)
	s.affinity = int(d.initial.affinity)
	s.known_facts = d.get("known_facts", []).duplicate()
	s.stance = DialogueRules.compute_stance(s)
	return s


func display_name() -> String:
	return str(def.get("name", id))


func is_antagonist() -> bool:
	return bool(def.get("is_antagonist", false))


func knows(fact_id: String) -> bool:
	return known_facts.has(fact_id)


func learn(fact_id: String) -> bool:
	if known_facts.has(fact_id):
		return false
	known_facts.append(fact_id)
	return true


func is_accomplice() -> bool:
	return stance == "共犯"


func is_joined() -> bool:
	return bool(flags.get("joined", false)) and stance != "敌对"


func to_dict() -> Dictionary:
	return {
		"id": id, "trust": trust, "suspicion": suspicion, "affinity": affinity, "stance": stance,
		"known_facts": known_facts, "player_claims": player_claims, "heard_claims": heard_claims,
		"contradictions": contradictions, "memory_summary": memory_summary,
		"recent_dialogue": recent_dialogue, "transcript": transcript, "flags": flags,
	}


func load_dict(d: Dictionary) -> void:
	trust = int(d.get("trust", trust))
	suspicion = int(d.get("suspicion", suspicion))
	affinity = int(d.get("affinity", affinity))
	known_facts = d.get("known_facts", known_facts)
	player_claims = d.get("player_claims", [])
	heard_claims = d.get("heard_claims", [])
	contradictions = d.get("contradictions", [])
	memory_summary = str(d.get("memory_summary", ""))
	recent_dialogue = d.get("recent_dialogue", [])
	transcript = d.get("transcript", [])
	flags = d.get("flags", {})
	talked_today = false
	stance = DialogueRules.compute_stance(self)


func record(who: String, text: String, loc: String) -> void:
	transcript.append({"who": who, "text": text, "day": GameState.day, "slot": GameState.slot, "loc": loc})
