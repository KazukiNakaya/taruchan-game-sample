class_name ButterflyEvent
extends Node
## 蝶々の寄り道イベント。小道の入口近くに蝶々を置き、森の少し奥まった場所に隠しいいもの(レア度2以上)を置く。
## 蝶々を追いかけると、その場所へ案内される。

@export var butterfly_scene: PackedScene
@export var treasure_scene: PackedScene
## 蝶々が最初に待っている小道上の位置(z)。入口から少し進んだあたり
@export var butterfly_z: float = -7.0
## 隠しいいものを置く範囲(小道の中心線からの距離 m、z の範囲)
@export var hidden_offset: Vector2 = Vector2(4.0, 8.0)
@export var hidden_z_range: Vector2 = Vector2(-34.0, -14.0)
## 木の幹からこれ以上(m)離れた場所に置く
@export var min_tree_distance: float = 0.9


func _ready() -> void:
	_spawn.call_deferred()


func _spawn() -> void:
	var data := _pick_data()
	if data == null:
		return
	var treasure := treasure_scene.instantiate() as Treasure
	treasure.data = data
	treasure.hidden_by_butterfly = true
	treasure.position = _pick_hidden_spot()
	get_parent().add_child(treasure)

	var butterfly := butterfly_scene.instantiate() as Butterfly
	get_parent().add_child(butterfly)
	var home := Vector3(ForestBuilder.path_x(butterfly_z) + 1.2, 0.8, butterfly_z)
	butterfly.setup(treasure, home)


## レア度2以上のものからランダムに1つ
func _pick_data() -> TreasureData:
	var candidates: Array[TreasureData] = []
	for data in GameState.CATALOG.treasures:
		if data.rarity >= 2:
			candidates.append(data)
	return candidates.pick_random() if not candidates.is_empty() else null


func _pick_hidden_spot() -> Vector3:
	var builder := get_tree().get_first_node_in_group(&"surface_map") as ForestBuilder
	var spot := Vector3.ZERO
	for attempt in 40:
		var z := randf_range(hidden_z_range.x, hidden_z_range.y)
		var side := -1.0 if randf() < 0.5 else 1.0
		spot = Vector3(ForestBuilder.path_x(z) + side * randf_range(hidden_offset.x, hidden_offset.y), 0.0, z)
		if builder == null or builder.min_tree_distance(spot) > min_tree_distance:
			break
	return spot
