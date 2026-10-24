class_name NameEntry
extends PanelContainer
## ランキングに登録する名前の入力(アーケード式の3文字)。
## ↑↓ / 十字キーで文字を変え、←→ で桁を移動、Enter(パッドはA)で次へ・最後で決定。英数字は直接打ってもよい。

signal confirmed(player_name: String)

const CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var _indices: Array[int] = []
var _cursor: int = 0
var _slots: Array[Label] = []


func _ready() -> void:
	for i in Ranking.NAME_LENGTH:
		_indices.append(0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	box.add_child(_label("ランキングに のりました!", 32))
	box.add_child(_label("%d文字の なまえを いれてね" % Ranking.NAME_LENGTH, 20))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	for i in Ranking.NAME_LENGTH:
		var column := VBoxContainer.new()
		row.add_child(column)
		column.add_child(_arrow_button("▲", i, 1))
		var slot := _label("", 64)
		slot.custom_minimum_size.x = 70
		column.add_child(slot)
		_slots.append(slot)
		column.add_child(_arrow_button("▼", i, -1))

	var ok := Button.new()
	ok.text = "けってい (Enter)"
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(_confirm)
	box.add_child(ok)
	box.add_child(_label("↑↓ もじ   ←→ けた   Enter けってい", 16))
	_refresh()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var typed := char(key.unicode).to_upper() if key.unicode > 0 else ""
		if typed != "" and CHARS.contains(typed):
			_indices[_cursor] = CHARS.find(typed)
			_move_cursor(1)
			_handled()
			return
		if key.keycode == KEY_BACKSPACE:
			_move_cursor(-1)
			_handled()
			return
	if event.is_action_pressed("ui_up"):
		_step(_cursor, 1)
	elif event.is_action_pressed("ui_down"):
		_step(_cursor, -1)
	elif event.is_action_pressed("ui_left"):
		_move_cursor(-1)
	elif event.is_action_pressed("ui_right"):
		_move_cursor(1)
	elif event.is_action_pressed("ui_accept"):
		if _cursor == Ranking.NAME_LENGTH - 1:
			_confirm()
		else:
			_move_cursor(1)
	else:
		return
	_handled()


func _handled() -> void:
	get_viewport().set_input_as_handled()


func _step(slot: int, direction: int) -> void:
	_cursor = slot
	_indices[slot] = posmod(_indices[slot] + direction, CHARS.length())
	AudioManager.play_ui(&"ui_click")
	_refresh()


func _move_cursor(direction: int) -> void:
	_cursor = clampi(_cursor + direction, 0, Ranking.NAME_LENGTH - 1)
	_refresh()


func _confirm() -> void:
	var text := ""
	for index in _indices:
		text += CHARS[index]
	confirmed.emit(text)


func _refresh() -> void:
	for i in _slots.size():
		_slots[i].text = CHARS[_indices[i]]
		_slots[i].modulate = Color(1, 0.8, 0.2) if i == _cursor else Color.WHITE


func _arrow_button(text: String, slot: int, direction: int) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_step.bind(slot, direction))
	return button


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
