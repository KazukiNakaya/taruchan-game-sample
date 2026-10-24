class_name Result
extends CanvasLayer
## おさんぽ終了時のリザルト。見つけたもの・時間・距離・スコアを表示し、TOP10に入ったら名前を登録する。

var _panel: PanelContainer
var _overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_result(found: Array[TreasureData], elapsed: float, distance: float, new_ids: PackedStringArray) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)
	_panel = panel

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(_label("おさんぽ おしまい", 32))
	box.add_child(_label("あるいた時間: %d分%02d秒    きょり: %.1f m" % [int(elapsed) / 60, int(elapsed) % 60, distance], 20))
	box.add_child(_label("みつけたもの  %d個中 %d個" % [GameState.total_treasures, found.size()], 24))
	if found.is_empty():
		box.add_child(_label("(なにも見つからなかった… また今度!)", 20))
	for data in found:
		var mark := "   ✨はじめて!" if new_ids.has(String(data.id)) else ""
		box.add_child(_label("%s  %s%s" % [data.stars(), data.display_name, mark], 20))

	var score: Dictionary = GameState.last_score
	box.add_child(_label("スコア  %d" % score["total"], 32))
	box.add_child(_label("(いいもの %d + タイム %d + ぜんぶあつめた %d)" % [score["treasure"], score["time"], score["complete"]], 16))

	var ranking_button := Button.new()
	ranking_button.text = "ランキングを見る"
	ranking_button.pressed.connect(func() -> void: _show_board(-1))
	box.add_child(ranking_button)
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
	if GameState.ranking.rank_for(score["total"], elapsed) >= 0:
		_open_name_entry(score["total"], elapsed)


## TOP10に入ったとき、結果の代わりに名前入力を出す
func _open_name_entry(score: int, elapsed: float) -> void:
	_panel.visible = false
	var entry := NameEntry.new()
	_set_overlay(entry)
	entry.confirmed.connect(func(player_name: String) -> void:
		var rank := GameState.ranking.add(player_name, score, elapsed, GameState.found.size(), GameState.total_treasures)
		_show_board(rank))


## ランキング表を出す。highlight は強調する順位(0始まり、-1で強調なし)
func _show_board(highlight: int) -> void:
	_panel.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var title := _label("ランキング TOP%d" % Ranking.MAX_ENTRIES, 32)
	box.add_child(title)
	var board := RankingBoard.new()
	box.add_child(board)
	board.show_entries(highlight)
	var close := Button.new()
	close.text = "とじる"
	close.pressed.connect(_close_overlay)
	box.add_child(close)
	var holder := PanelContainer.new()
	holder.add_child(box)
	_set_overlay(holder)
	close.grab_focus()


func _set_overlay(control: Control) -> void:
	if _overlay:
		_overlay.queue_free()
	_overlay = control
	add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _close_overlay() -> void:
	_overlay.queue_free()
	_overlay = null
	_panel.visible = true
	for button in _panel.find_children("*", "Button", true, false):
		(button as Button).grab_focus()
		break


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
