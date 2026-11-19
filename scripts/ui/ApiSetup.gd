class_name ApiSetup
extends Control
## 连接设置：填写 DeepSeek Key，测试连接成功后才能开始游戏。

signal done(verified: bool)

var _key: LineEdit
var _url: LineEdit
var _model: LineEdit
var _status: RichTextLabel
var _test_btn: Button
var _ok_btn: Button
var _verified := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiKit.dim_layer(0.85))
	var panel := UiKit.centered_panel(self, Vector2(760, 540))
	var v := VBoxContainer.new()
	panel.add_child(v)
	v.add_child(UiKit.label("连接设置", 26, UiKit.C_GOLD, UiKit.SANS_BOLD))
	v.add_child(UiKit.wrap_label("本作的 NPC 对话由 DeepSeek 大模型实时生成，必须联网并填写可用的 API Key。Key 只保存在本机（%s），不会写进游戏文件。也可以用环境变量 DEEPSEEK_API_KEY 提供。" % ProjectSettings.globalize_path(LlmClient.SECRETS_PATH), 15, UiKit.C_DIM))
	_key = _field(v, "API Key", LlmClient.api_key, "sk-……")
	_key.secret = true
	var show := CheckBox.new()
	show.text = "显示 Key"
	show.toggled.connect(func(on): _key.secret = not on)
	v.add_child(show)
	_url = _field(v, "Base URL", LlmClient.base_url, LlmClient.DEFAULT_BASE_URL)
	_model = _field(v, "模型名", LlmClient.model, LlmClient.DEFAULT_MODEL)
	_status = UiKit.rich(false, 16)
	_status.fit_content = true
	_status.custom_minimum_size = Vector2(0, 60)
	v.add_child(_status)
	if LlmClient.is_verified():
		_verified = true
		_status.text = "[color=#8fc284]已连接过。修改后需要重新测试。[/color]"
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	_test_btn = UiKit.primary_button("测试连接", _on_test)
	h.add_child(_test_btn)
	_ok_btn = UiKit.button("完成", func(): done.emit(_verified))
	h.add_child(_ok_btn)
	v.add_child(h)
	for f in [_key, _url, _model]:
		f.text_changed.connect(func(_t): _verified = false)


func _field(parent: Control, label_text: String, value: String, placeholder: String) -> LineEdit:
	var h := HBoxContainer.new()
	var l := UiKit.label(label_text, 17)
	l.custom_minimum_size = Vector2(110, 0)
	h.add_child(l)
	var e := LineEdit.new()
	e.text = value
	e.placeholder_text = placeholder
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.custom_minimum_size = Vector2(0, 40)
	h.add_child(e)
	parent.add_child(h)
	return e


func _on_test() -> void:
	LlmClient.save_config(_key.text, _url.text, _model.text)
	_test_btn.disabled = true
	_ok_btn.disabled = true
	_status.text = "[color=#a59b8b]正在连接 %s ……[/color]" % LlmClient.base_url
	var res: Dictionary = await LlmClient.test_connection()
	_test_btn.disabled = false
	_ok_btn.disabled = false
	if res.ok:
		_verified = true
		LlmClient.mark_verified(true)
		_status.text = "[color=#8fc284]√ 连接成功（延迟 %d ms）。可以开始游戏了。[/color]" % LlmClient.last_latency_ms
	else:
		_verified = false
		LlmClient.mark_verified(false)
		var kind := "Key / 账户问题" if LlmClient.error_is_key_problem(res.error_kind) else "网络问题"
		_status.text = "[color=#e2715d]× 连接失败（%s）：%s[/color]" % [kind, res.message]
