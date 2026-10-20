class_name Stage
extends Node3D
## おさんぽ1回ぶんの進行(開始 → 発見 → ゴール → リザルト)。

@export var player: Taruchan
@export var goal: Goal
@export var hud: Hud
@export var result_scene: PackedScene


func _ready() -> void:
	GameState.start_walk()
	var sensor := player.get_node("SniffSensor") as SniffSensor
	sensor.treasure_found.connect(GameState.add_found)
	hud.bind(sensor)
	goal.reached.connect(_on_goal_reached, CONNECT_ONE_SHOT)


func _on_goal_reached() -> void:
	GameState.finish_walk()
	var result := result_scene.instantiate() as Result
	add_child(result)
	result.show_result(GameState.found, GameState.elapsed, GameState.distance)
	get_tree().paused = true
