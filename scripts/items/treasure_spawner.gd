class_name TreasureSpawner
extends Node
## "spawn_points" グループの Marker3D から、重み付き抽選でいいものを配置する。

@export var treasure_scene: PackedScene
@export var treasures: Array[TreasureData] = []
## 配置する数(スポーン地点より多くは置けない)
@export var count: int = 5


func _ready() -> void:
	spawn()


func spawn() -> void:
	var points := get_tree().get_nodes_in_group(&"spawn_points")
	points.shuffle()
	for i in mini(count, points.size()):
		var point := points[i] as Node3D
		var treasure := treasure_scene.instantiate() as Treasure
		treasure.data = _pick()
		treasure.position = point.position
		get_parent().add_child.call_deferred(treasure)


func _pick() -> TreasureData:
	var total := 0.0
	for data in treasures:
		total += data.spawn_weight
	var roll := randf() * total
	for data in treasures:
		roll -= data.spawn_weight
		if roll <= 0.0:
			return data
	return treasures.back()
