class_name Result
extends CanvasLayer
## おさんぽ終了時のリザルト。見つけたもの・時間・距離を表示する。


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_result(found: Array[TreasureData], elapsed: float, distance: float, new_ids: PackedStringArray) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(_label("おさんぽ おしまい", 32))
	box.add_child(_label("あるいた時間: %d分%02d秒    きょり: %.1f m" % [int(elapsed) / 60, int(elapsed) % 60, distance], 20))
	box.add_child(_label("みつけたもの (%d)" % found.size(), 24))
	if found.is_empty():
		box.add_child(_label("(なにも見つからなかった… また今度!)", 20))
	for data in found:
		var mark := "   ✨はじめて!" if new_ids.has(String(data.id)) else ""
		box.add_child(_label("%s  %s%s" % [data.stars(), data.display_name, mark], 20))

	var again := Button.new()
	again.text = "もういちど さんぽする"
	again.pressed.connect(_on_again_pressed)
	box.add_child(again)
	var to_title := Button.new()
	to_title.text = "タイトルにもどる"
	to_title.pressed.connect(_on_title_pressed)
	box.add_child(to_title)
	var quit := Button.new()
	quit.text = "おわる"
	quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit)
	again.grab_focus()
	panel.reset_size()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _on_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
