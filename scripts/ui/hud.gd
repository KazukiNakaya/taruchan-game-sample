class_name Hud
extends CanvasLayer
## おさんぽ中の表示。クンクンのゲージ、発見メッセージ、見つけた数。

var _gauge: ProgressBar
var _toast: Label
var _counter: Label
var _toast_tween: Tween


func _ready() -> void:
	_gauge = ProgressBar.new()
	_gauge.max_value = 1.0
	_gauge.show_percentage = false
	_gauge.custom_minimum_size = Vector2(240, 14)
	_gauge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 80)
	_gauge.visible = false
	add_child(_gauge)

	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 60)
	_toast.add_theme_font_size_override("font_size", 32)
	_outline(_toast)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	# 左上: 全体マップと、その下に見つけた個数
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(16, 16)
	top_left.add_theme_constant_override("separation", 6)
	add_child(top_left)
	top_left.add_child(ForestMap.new())
	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", 22)
	_outline(_counter)
	top_left.add_child(_counter)
	add_child(ControlsGuide.new())
	_update_counter()
	GameState.treasure_added.connect(func(_d: TreasureData) -> void: _update_counter())
	GameState.total_changed.connect(func(_t: int) -> void: _update_counter())


## 明るい空や地面の上でも読めるように、縁取りと影をつける
func _outline(label: Label) -> void:
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.08, 0.95))
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func bind(sensor: SniffSensor) -> void:
	sensor.progress_changed.connect(_on_progress_changed)
	sensor.treasure_found.connect(_on_treasure_found)


func _on_progress_changed(value: float) -> void:
	_gauge.value = value
	_gauge.visible = value > 0.0


func _on_treasure_found(data: TreasureData) -> void:
	show_message("%s をみつけた!  %s" % [data.display_name, data.stars()])


## 画面上部の中央に、短いメッセージを出す(しばらくすると消える)
func show_message(text: String) -> void:
	_toast.text = text
	_toast.reset_size()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 60)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast.modulate.a = 1.0
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _update_counter() -> void:
	_counter.text = "みつけた: %d / %d" % [GameState.found.size(), GameState.total_treasures]
