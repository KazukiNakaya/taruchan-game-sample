class_name Stage
extends Node3D
## おさんぽ1回ぶんの進行(開始 → 発見 → ゴール → リザルト)。

@export var player: Taruchan
@export var goal: Goal
@export var hud: Hud
@export var result_scene: PackedScene

const MENU_SCENE := preload("res://scenes/ui/menu.tscn")

var _menu: Menu


func _ready() -> void:
	GameState.start_walk()
	AudioManager.start_bgm()
	AudioManager.start_ambient()
	var sensor := player.get_node("SniffSensor") as SniffSensor
	sensor.treasure_found.connect(GameState.add_found)
	hud.bind(sensor)
	_menu = MENU_SCENE.instantiate() as Menu
	add_child(_menu)
	goal.reached.connect(_on_goal_reached, CONNECT_ONE_SHOT)


func _exit_tree() -> void:
	AudioManager.stop_ambient()


func _on_goal_reached() -> void:
	AudioManager.stop_ambient()
	AudioManager.play_sfx(&"goal")
	_menu.enabled = false
	GameState.finish_walk()
	var result := result_scene.instantiate() as Result
	add_child(result)
	result.show_result(GameState.found, GameState.elapsed, GameState.distance, GameState.last_new_ids)
	get_tree().paused = true
