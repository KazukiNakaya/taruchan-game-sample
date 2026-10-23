class_name ControlsGuide
extends PanelContainer
## 画面の右上に出す操作一覧。最後に使った入力(キーボード/パッド)で表示を切り替える。
## 割り当てを変えたときは、project.godot の入力マップと下の表を合わせる。

## 操作の一覧: [表示名, キーボード/マウス, パッド]
const ENTRIES: Array = [
	["うごく", "W A S D", "左スティック"],
	["はしる", "Shift (おしっぱなし)", "LT / L2"],
	["ジャンプ", "Space", "B / ○"],
	["おすわり", "Ctrl / C", "Y / △"],
	["クンクン", "E (ながおし)", "A / ✕ (ながおし)"],
	["カメラ", "マウス", "右スティック"],
	["メニュー", "Tab / Esc", "Start"],
]
## スティックの傾きがこれ以下なら、パッド操作とみなさない(ノイズ対策)
const AXIS_THRESHOLD: float = 0.5

var _use_pad: bool = false
var _key_labels: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.38)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	add_child(grid)
	for entry in ENTRIES:
		var name_label := _label(entry[0], Color(0.85, 0.95, 0.8))
		var key_label := _label("", Color.WHITE)
		grid.add_child(name_label)
		grid.add_child(key_label)
		_key_labels.append(key_label)
	_refresh()
	# 右上に固定(内容に合わせて左へ伸びる)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _input(event: InputEvent) -> void:
	var pad := _use_pad
	if event is InputEventKey or event is InputEventMouseButton:
		pad = false
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 1.0:
		pad = false
	elif event is InputEventJoypadButton:
		pad = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > AXIS_THRESHOLD:
		pad = true
	if pad != _use_pad:
		_use_pad = pad
		_refresh()


func _refresh() -> void:
	for i in ENTRIES.size():
		_key_labels[i].text = ENTRIES[i][2] if _use_pad else ENTRIES[i][1]
	reset_size()
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.04, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	return label
