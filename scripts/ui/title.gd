class_name Title
extends Control
## タイトル画面(起動シーン)。はじめる / にっき・ずかん / おわる。

const WALK_SCENE := "res://scenes/stages/forest_path.tscn"
const MENU_SCENE := preload("res://scenes/ui/menu.tscn")

var _menu: Menu
var _buttons: Array[Button] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	AudioManager.start_bgm()
	_build_ui()
	_menu = MENU_SCENE.instantiate() as Menu
	_menu.pause_game = false
	_menu.enabled = false
	_menu.closed.connect(_on_menu_closed)
	add_child(_menu)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.72, 0.85, 0.7)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	add_child(box)

	var title := Label.new()
	title.text = "たるちゃんの おさんぽ"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.2, 0.3, 0.15))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var start := _button("はじめる", _on_start_pressed)
	box.add_child(start)
	box.add_child(_button("にっき・ずかん", _on_book_pressed))
	box.add_child(_button("おわる", func() -> void: get_tree().quit()))
	start.grab_focus()
	box.reset_size()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 48)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(handler)
	_buttons.append(button)
	return button


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(WALK_SCENE)


func _on_book_pressed() -> void:
	# メニューを開いている間は、後ろのボタンにフォーカスが移らないようにする
	for button in _buttons:
		button.focus_mode = Control.FOCUS_NONE
	_menu.open()


func _on_menu_closed() -> void:
	for button in _buttons:
		button.focus_mode = Control.FOCUS_ALL
	_buttons[0].grab_focus()
