extends Node
## 全局状态：天数/时段、疑云值、事实库、NPC 状态、事件、存档。

signal state_changed

const SLOTS := ["上午", "下午", "傍晚", "夜晚"]
const SLOT_KEYS := ["morning", "afternoon", "evening", "night"]
const LAST_DAY := 7
const SAVE_DIR := "user://saves"

var facts: Dictionary = {}
var clues: Dictionary = {}
var locations: Dictionary = {}
var npc_defs: Dictionary = {}
var prompt_npc_system: String = ""
var prompt_summary_system: String = ""

var npcs: Dictionary = {}           # id -> NpcState
var day: int = 1
var slot: int = 0
var doubt: int = 20                 # 全局疑云值 0-100
var doubt_today: Array = []         # [{delta, reason}] 今天发生的疑云变化（夜间结算展示）
var player_facts: Array = []
var flags: Dictionary = {}
var event_notes: Array = []         # 所有 NPC 都知道的公共事件，会写进 prompt
var journal: Array = []             # 给玩家看的行动日志
var cards: Array = []               # 玩家手里的线索卡 ID
var toasts: Array = []              # 待显示的提示（回到地图时弹出，不存档）


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	facts = _read_json("res://data/facts.json")
	clues = _read_json("res://data/clues.json")
	locations = _read_json("res://data/locations.json")
	npc_defs.clear()
	for id in ["knight_reinhardt", "apprentice_mia", "scholar_oswald", "thief_nova", "priest_seraphim"]:
		npc_defs[id] = _read_json("res://data/npcs/%s.json" % id)
	prompt_npc_system = FileAccess.get_file_as_string("res://data/prompts/npc_system.txt")
	prompt_summary_system = FileAccess.get_file_as_string("res://data/prompts/summary_system.txt")


func _read_json(path: String) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY:
		push_error("无法读取 " + path)
		return {}
	return d


# ------------------------------------------------------------------ 新游戏 / 时间

func new_game() -> void:
	npcs.clear()
	for id in npc_defs:
		npcs[id] = NpcState.from_def(npc_defs[id])
	day = 1
	slot = 1   # 第 1 天上午是仪式（开场过场）
	doubt = 20
	doubt_today.clear()
	player_facts = ["F_PLAYER_NO_POWER", "F_RITUAL_FAKE"]
	flags = {"confessed_to": []}
	event_notes = ["第1天上午，大神殿举行了圣剑择主仪式，圣剑在万众瞩目下发光，选中了勇者。"]
	journal = ["第1天 上午：圣剑择主仪式。你被选中了。"]
	cards = []
	toasts = []
	state_changed.emit()


func slot_name() -> String:
	return SLOTS[clampi(slot, 0, 3)]


func time_label() -> String:
	return "第 %d 天 · %s" % [day, slot_name()]


func days_left() -> int:
	return LAST_DAY - day


func advance_slot() -> bool:
	## 推进一个时段。返回 true 表示今天结束了，需要夜间结算。
	slot += 1
	state_changed.emit()
	return slot > 3


func npcs_at(loc_id: String) -> Array:
	var res: Array = []
	if is_feast():
		return []
	var key: String = SLOT_KEYS[clampi(slot, 0, 3)]
	for id in npcs:
		var n: NpcState = npcs[id]
		var sched: Dictionary = n.def.get("schedule", {})
		if str(sched.get(key, "")) == loc_id:
			res.append(id)
	return res


func is_feast() -> bool:
	return day == LAST_DAY and slot == 3


# ------------------------------------------------------------------ 固定事件

func pending_event() -> String:
	## 当前时段是否有强制事件。返回事件 ID 或 ""。
	var key := "%d_%d" % [day, slot]
	if flags.get("done_" + key, false):
		return ""
	if day == 2 and slot == 0:
		return "priest_summon"
	if day == 3 and slot == 1:
		return "knight_test"
	if day == 5 and slot == 0:
		return "sermon"
	if day == 6 and slot == 3 and not bool(npcs.thief_nova.flags.get("met", false)):
		return "nova_visit"
	if day == 7 and slot == 3:
		return "feast"
	return ""


func mark_event_done() -> void:
	flags["done_%d_%d" % [day, slot]] = true


# ------------------------------------------------------------------ 事实 / 疑云

func fact_text(id: String) -> String:
	return str(facts.get(id, {}).get("text", id))


func fact_short(id: String) -> String:
	return str(facts.get(id, {}).get("short", id))


func player_knows(id: String) -> bool:
	return player_facts.has(id)


func player_learn(id: String) -> bool:
	if id.is_empty() or player_facts.has(id) or not facts.has(id):
		return false
	player_facts.append(id)
	journal.append("%s：你得知了「%s」" % [time_label(), fact_short(id)])
	return true


func add_doubt(delta: int, reason: String) -> void:
	doubt = clampi(doubt + delta, 0, 100)
	doubt_today.append({"delta": delta, "reason": reason})
	state_changed.emit()


func add_event_note(text: String) -> void:
	event_notes.append(text)
	if event_notes.size() > 8:
		event_notes = event_notes.slice(event_notes.size() - 8)


func on_confession(n: NpcState) -> void:
	var arr: Array = flags.get("confessed_to", [])
	if not arr.has(n.id):
		arr.append(n.id)
	flags.confessed_to = arr
	journal.append("%s：你向 %s 坦白了。" % [time_label(), n.display_name()])


func log_journal(text: String) -> void:
	journal.append("%s：%s" % [time_label(), text])


# ------------------------------------------------------------------ 夜间结算

func night_settlement() -> Array:
	## 传话 + 疑云值结算。返回给过场看的文字。记忆压缩在 NpcBrain.compress_memories 中单独完成。
	var lines: Array = GossipSystem.run_night(self)
	# 疑云值：公开场合有发言权的人的怀疑程度
	var public := ["knight_reinhardt", "apprentice_mia", "scholar_oswald"]
	var total := 0
	var count := 0
	for id in public:
		var n: NpcState = npcs[id]
		if n.is_accomplice():
			continue
		total += n.suspicion
		count += 1
	var drift := 0
	if count > 0:
		drift = int(round((float(total) / count - 45.0) / 6.0))
	if npcs.apprentice_mia.stance == "崇拜":
		drift -= 3
	for id in npcs:
		var n: NpcState = npcs[id]
		if n.stance == "敌对" and not n.is_antagonist():
			drift += 4
	drift = clampi(drift, -8, 10)
	if drift != 0:
		add_doubt(drift, "王都的风向" + ("变好了" if drift < 0 else "对你不利"))
	for id in npcs:
		npcs[id].stance = DialogueRules.compute_stance(npcs[id])
	return lines


func start_next_day() -> void:
	day += 1
	slot = 0
	doubt_today.clear()
	for id in npcs:
		npcs[id].talked_today = false
	state_changed.emit()


# ------------------------------------------------------------------ 存档

func to_dict() -> Dictionary:
	var nd := {}
	for id in npcs:
		nd[id] = npcs[id].to_dict()
	return {
		"version": 1, "day": day, "slot": slot, "doubt": doubt,
		"player_facts": player_facts, "flags": flags, "event_notes": event_notes,
		"journal": journal, "cards": cards, "npcs": nd,
		"saved_at": Time.get_datetime_string_from_system(false, true),
	}


func load_dict(d: Dictionary) -> void:
	new_game()
	day = int(d.get("day", 1))
	slot = int(d.get("slot", 0))
	doubt = int(d.get("doubt", 20))
	player_facts = d.get("player_facts", player_facts)
	flags = d.get("flags", flags)
	event_notes = d.get("event_notes", [])
	journal = d.get("journal", [])
	cards = d.get("cards", [])
	var nd: Dictionary = d.get("npcs", {})
	for id in nd:
		if npcs.has(id):
			npcs[id].load_dict(nd[id])
	state_changed.emit()


func save_day() -> void:
	## 夜间结算后调用：保存为“第 day 天早晨”。
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open("%s/day_%d.json" % [SAVE_DIR, day], FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict(), "\t"))
		f.close()


func list_saves() -> Array:
	var res: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return res
	for fn in dir.get_files():
		if fn.begins_with("day_") and fn.ends_with(".json"):
			var d := int(fn.trim_prefix("day_").trim_suffix(".json"))
			res.append(d)
	res.sort()
	return res


func load_save(d: int) -> bool:
	var path := "%s/day_%d.json" % [SAVE_DIR, d]
	if not FileAccess.file_exists(path):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	load_dict(data)
	return true


func delete_saves_after(d: int) -> void:
	## 新游戏时清掉旧存档。
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	for fn in dir.get_files():
		if fn.begins_with("day_"):
			var n := int(fn.trim_prefix("day_").trim_suffix(".json"))
			if n > d:
				dir.remove(fn)


# ------------------------------------------------------------------ 提示

func toast(text: String) -> void:
	toasts.append(text)


func toast_all(lines: Array) -> void:
	for l in lines:
		toast(str(l))


## 检查所有目标，把结果放进提示队列（在对话以外的地方调用）
func check_goals() -> void:
	toast_all(GoalSystem.check_all(self))
