extends Node
## DeepSeek（OpenAI 兼容 Chat Completions）客户端。
## - Key 从环境变量 DEEPSEEK_API_KEY 或 user://secrets.cfg 读取，绝不写进代码。
## - 所有请求返回统一结构：
##   {ok: bool, content: String, error_kind: String, message: String, usage: Dictionary}
##   error_kind: "" / "network" / "timeout" / "key" / "balance" / "rate" / "server" / "bad_request" / "parse"
## - 开发用：命令行带 --mock-llm 时使用本地假回复（只用于自动化测试，不面向玩家）。

const SECRETS_PATH := "user://secrets.cfg"
const DEFAULT_BASE_URL := "https://api.deepseek.com"
const DEFAULT_MODEL := "deepseek-chat"
const TIMEOUT_SEC := 60.0

var api_key: String = ""
var base_url: String = DEFAULT_BASE_URL
var model: String = DEFAULT_MODEL
var mock: bool = false

# 统计
var total_prompt_tokens: int = 0
var total_completion_tokens: int = 0
var total_cache_hit_tokens: int = 0
var request_count: int = 0
var failed_count: int = 0
var last_latency_ms: int = 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	mock = args.has("--mock-llm")
	load_config()


func load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SECRETS_PATH) == OK:
		api_key = str(cfg.get_value("deepseek", "api_key", ""))
		base_url = str(cfg.get_value("deepseek", "base_url", DEFAULT_BASE_URL))
		model = str(cfg.get_value("deepseek", "model", DEFAULT_MODEL))
	if api_key.is_empty():
		api_key = OS.get_environment("DEEPSEEK_API_KEY")


func save_config(key: String, url: String, model_name: String) -> void:
	api_key = key.strip_edges()
	base_url = url.strip_edges().trim_suffix("/")
	if base_url.is_empty():
		base_url = DEFAULT_BASE_URL
	model = model_name.strip_edges()
	if model.is_empty():
		model = DEFAULT_MODEL
	var cfg := ConfigFile.new()
	cfg.set_value("deepseek", "api_key", api_key)
	cfg.set_value("deepseek", "base_url", base_url)
	cfg.set_value("deepseek", "model", model)
	cfg.save(SECRETS_PATH)


func is_configured() -> bool:
	return mock or not api_key.is_empty()


func is_verified() -> bool:
	## 是否已经测试连接成功过（存在 secrets.cfg 中）。
	if mock:
		return true
	var cfg := ConfigFile.new()
	if cfg.load(SECRETS_PATH) != OK:
		return false
	return bool(cfg.get_value("deepseek", "verified", false)) and not api_key.is_empty()


func mark_verified(v: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SECRETS_PATH)
	cfg.set_value("deepseek", "verified", v)
	cfg.save(SECRETS_PATH)


func test_connection() -> Dictionary:
	var res := await chat([
		{"role": "system", "content": "你是连接测试助手。只输出 json。"},
		{"role": "user", "content": "请输出 json：{\"ok\": true}"},
	], true, 20)
	if res.ok:
		var parsed = parse_json_content(res.content)
		if parsed == null:
			res.ok = false
			res.error_kind = "parse"
			res.message = "连接成功，但模型没有按 JSON 格式回复。请检查模型名是否正确。"
	return res


func chat(messages: Array, json_mode: bool = true, max_tokens: int = 900, temperature: float = 1.0) -> Dictionary:
	if mock:
		return await _mock_chat(messages)
	if api_key.is_empty():
		return _err("key", "还没有填写 API Key。")
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SEC
	add_child(http)
	var body := {
		"model": model,
		"messages": messages,
		"max_tokens": max_tokens,
		"temperature": temperature,
		"stream": false,
	}
	if json_mode:
		body["response_format"] = {"type": "json_object"}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
	])
	var t0 := Time.get_ticks_msec()
	var err := http.request(base_url + "/chat/completions", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		failed_count += 1
		return _err("network", "无法发起请求（错误码 %d），请检查网络或 Base URL。" % err)
	var r: Array = await http.request_completed
	http.queue_free()
	last_latency_ms = Time.get_ticks_msec() - t0
	request_count += 1
	var result: int = r[0]
	var code: int = r[1]
	var raw: PackedByteArray = r[3]
	if result == HTTPRequest.RESULT_TIMEOUT:
		failed_count += 1
		return _err("timeout", "请求超时（%d 秒），可能是网络或服务端繁忙。" % int(TIMEOUT_SEC))
	if result != HTTPRequest.RESULT_SUCCESS:
		failed_count += 1
		return _err("network", "网络连接失败（HTTPRequest 结果 %d）。请检查网络、代理或 Base URL。" % result)
	var text := raw.get_string_from_utf8()
	if code != 200:
		failed_count += 1
		var detail := _extract_error_message(text)
		match code:
			401, 403:
				return _err("key", "API Key 无效或没有权限（HTTP %d）。%s" % [code, detail])
			402:
				return _err("balance", "账户余额不足（HTTP 402）。请到 DeepSeek 控制台充值。")
			429:
				return _err("rate", "请求太频繁（HTTP 429），请稍后重试。")
			400, 404, 422:
				return _err("bad_request", "请求参数有误（HTTP %d），请检查模型名和 Base URL。%s" % [code, detail])
			_:
				return _err("server", "服务端错误（HTTP %d），请稍后重试。%s" % [code, detail])
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY or not data.has("choices") or data.choices.is_empty():
		failed_count += 1
		return _err("server", "服务端返回了无法识别的内容。")
	var usage: Dictionary = data.get("usage", {}) if data.get("usage") is Dictionary else {}
	total_prompt_tokens += int(usage.get("prompt_tokens", 0))
	total_completion_tokens += int(usage.get("completion_tokens", 0))
	total_cache_hit_tokens += int(usage.get("prompt_cache_hit_tokens", 0))
	var content = data.choices[0].get("message", {}).get("content", "")
	return {"ok": true, "content": str(content), "error_kind": "", "message": "", "usage": usage}


func _err(kind: String, msg: String) -> Dictionary:
	return {"ok": false, "content": "", "error_kind": kind, "message": msg, "usage": {}}


func _extract_error_message(text: String) -> String:
	var d = JSON.parse_string(text)
	if typeof(d) == TYPE_DICTIONARY and d.get("error") is Dictionary:
		return str(d.error.get("message", ""))
	return ""


static func parse_json_content(content: String):
	## 宽松解析：去掉 ```json 包裹，截取第一个 { 到最后一个 }。失败返回 null。
	var s := content.strip_edges()
	var a := s.find("{")
	var b := s.rfind("}")
	if a < 0 or b <= a:
		return null
	var d = JSON.parse_string(s.substr(a, b - a + 1))
	if typeof(d) != TYPE_DICTIONARY:
		return null
	return d


func error_is_key_problem(kind: String) -> bool:
	return kind in ["key", "balance", "bad_request"]


# ---------------------------------------------------------------- 开发用假模型

func _mock_chat(messages: Array) -> Dictionary:
	await get_tree().create_timer(0.05).timeout
	request_count += 1
	var sys: String = str(messages[0].content)
	var user: String = str(messages[-1].content)
	if sys.contains("记忆整理"):
		return {"ok": true, "content": JSON.stringify({"summary": "（测试摘要）我和勇者聊过几次。"}), "error_kind": "", "message": "", "usage": {}}
	if sys.contains("连接测试"):
		return {"ok": true, "content": "{\"ok\": true}", "error_kind": "", "message": "", "usage": {}}
	var line := ""
	for marker in ["【勇者接着对你说】", "【勇者这一轮说的话】"]:
		var idx := user.rfind(marker)
		if idx >= 0:
			line = user.substr(idx + marker.length()).get_slice("\n\n", 0).strip_edges()
			break
	var confessed := line.contains("没有神力") or line.contains("我是假的")
	var action := "none"
	if line.contains("加入") or line.contains("一起出征"):
		action = "join_party"
	elif line.contains("帮") and line.contains("考验"):
		action = "promise_help"
	elif line.contains("告诉我") or line.contains("情报") or line.contains("弱点"):
		action = "share_info"
	elif line.contains("逃"):
		action = "offer_escape"
	var revealed := []
	if line.contains("大祭司") and line.contains("主谋"):
		revealed.append("F_HIGH_PRIEST_PLOT")
	var out := {
		"reply": "（测试回复）你来了。" if line.begins_with("（勇者走了过来）") else "（测试回复）你说“%s”？我记下了。" % line.left(20),
		"emotion": ["neutral", "happy", "skeptical", "surprised"].pick_random(),
		"action": action,
		"trust_delta": 12 if (confessed or line.contains("相信")) else randi_range(-3, 6),
		"suspicion_delta": randi_range(-5, 5),
		"affinity_delta": randi_range(0, 5),
		"player_claims": [{"text": line.left(30), "topic": "power"}] if line.contains("神力") and not confessed else [],
		"player_confessed": confessed,
		"player_revealed_facts": revealed,
		"noticed_contradiction": null,
		"impression": ["总算说了句实在话", "他在回避我的问题", "有点意思"].pick_random(),
		"suggested_replies": [
			{"tactic": "说服", "text": "请相信我，我们需要你。"},
			{"tactic": "转移", "text": "魔王军最近有什么动向？"},
			{"tactic": "坦白", "text": "……其实我没有神力。"},
		],
	}
	return {"ok": true, "content": JSON.stringify(out), "error_kind": "", "message": "", "usage": {"prompt_tokens": 100, "completion_tokens": 50}}
