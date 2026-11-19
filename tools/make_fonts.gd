extends SceneTree
## 生成字体字重变体：godot --headless --path . --script res://tools/make_fonts.gd
## 思源宋体 = Noto Serif SC，思源黑体 = Noto Sans SC（同一套字形，SIL OFL 授权）。

const VARIANTS := {
	"serif_regular": ["NotoSerifSC-VF.ttf", 500],
	"serif_bold":    ["NotoSerifSC-VF.ttf", 700],
	"serif_black":   ["NotoSerifSC-VF.ttf", 900],
	"sans_regular":  ["NotoSansSC-VF.ttf", 400],
	"sans_medium":   ["NotoSansSC-VF.ttf", 500],
	"sans_bold":     ["NotoSansSC-VF.ttf", 700],
}

func _init() -> void:
	var ts := TextServerManager.get_primary_interface()
	for name in VARIANTS:
		var v: Array = VARIANTS[name]
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/" + v[0])
		fv.variation_opentype = {ts.name_to_tag("wght"): v[1]}
		var err := ResourceSaver.save(fv, "res://assets/fonts/%s.tres" % name)
		print(name, " -> ", err)
	quit()
