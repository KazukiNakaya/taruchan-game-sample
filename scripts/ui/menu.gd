class_name Menu
extends CanvasLayer
## おさんぽ日記と図鑑のメニュー。Tab(パッドは Start)で開閉する。

signal closed

## false の間は Tab で開閉できない(リザルト中など)
var enabled: bool = true
## おさんぽ中は開いている間ゲームを止める。タイトルから開くときは止めない
var pause_game: bool = true

var _tabs: TabContainer
var _diary_box: VBoxContainer
var _book_box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	visible = false
	_build_ui()


func is_open() -> bool:
	return visible


func open() -> void:
	_refresh()
	visible = true
	if pause_game:
		get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_tabs.grab_focus()


func close() -> void:
	visible = false
	if pause_game:
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not event.is_action_pressed("menu"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		close()
	else:
		open()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 460)
	panel.size = panel.custom_minimum_size
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)

	var box := VBoxContainer.new()
	panel.add_child(box)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_tabs)
	_diary_box = _add_scroll_tab("にっき")
	_book_box = _add_scroll_tab("ずかん")

	var close_button := Button.new()
	close_button.text = "とじる (Tab)"
	close_button.pressed.connect(close)
	box.add_child(close_button)


func _add_scroll_tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	return content


func _refresh() -> void:
	_fill_diary()
	_fill_book()


func _fill_diary() -> void:
	_clear(_diary_box)
	var diary := GameState.save_data.diary
	if diary.is_empty():
		_diary_box.add_child(_label("まだ おさんぽの きろくが ありません。", 20))
		return
	# 新しいおさんぽを上に
	for i in range(diary.size() - 1, -1, -1):
		_diary_box.add_child(_diary_page(i + 1, diary[i]))


func _diary_page(number: int, entry: DiaryEntry) -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label("%d ページめ   %s" % [number, entry.date_text], 20))
	box.add_child(_label("あるいた時間 %d分%02d秒   きょり %.1f m" % [int(entry.duration) / 60, int(entry.duration) % 60, entry.distance], 16))
	if entry.found_ids.is_empty():
		box.add_child(_label("みつけたもの: なし", 16))
	for id in entry.found_ids:
		var data := GameState.CATALOG.find(StringName(id))
		var name_text := data.display_name if data else id
		var stars := data.stars() if data else ""
		var mark := "  ✨はじめて!" if entry.new_ids.has(id) else ""
		box.add_child(_label("  %s %s%s" % [stars, name_text, mark], 16))
	return panel


func _fill_book() -> void:
	_clear(_book_box)
	var all := GameState.CATALOG.treasures
	var count := 0
	for data in all:
		if GameState.save_data.is_discovered(data.id):
			count += 1
	_book_box.add_child(_label("あつめた  %d / %d" % [count, all.size()], 22))
	for data in all:
		_book_box.add_child(_book_card(data))


func _book_card(data: TreasureData) -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	if GameState.save_data.is_discovered(data.id):
		box.add_child(_label("%s %s" % [data.stars(), data.display_name], 20))
		var desc := _label(data.description, 16)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.x = 600
		box.add_child(desc)
	else:
		# 未発見はシルエット表示
		var silhouette := _label("？？？  %s" % data.stars(), 20)
		silhouette.modulate = Color(1, 1, 1, 0.45)
		box.add_child(silhouette)
		box.add_child(_label("まだ みつけていない…", 16))
	return panel


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _clear(box: Control) -> void:
	for child in box.get_children():
		child.queue_free()
