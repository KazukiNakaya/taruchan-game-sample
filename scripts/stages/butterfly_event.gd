class_name ButterflyEvent
extends Node
## 蝶々の寄り道イベント。森の少し奥まった場所に隠しいいもの(レア度2以上)を最初から置き、
## 迷っているときだけ蝶々が飛んできて、その場所へ案内する。
## 出現条件(どちらか早い方): 最後の発見(または開始)から lost_time 秒見つからない / 開始から random_time 秒経った。
## 隠しいいものを先に見つけたら、蝶々は出ない。

signal appeared

@export var butterfly_scene: PackedScene
@export var treasure_scene: PackedScene
## 最後の発見(または開始)から、この秒数見つからないと蝶々が出る
@export var lost_time: float = 180.0
## 開始から、この範囲のランダムな秒数で蝶々が出る
@export var random_time_range: Vector2 = Vector2(60.0, 150.0)
## 隠しいいものを置く範囲(小道の中心線からの距離 m、z の範囲)
@export var hidden_offset: Vector2 = Vector2(4.0, 8.0)
@export var hidden_z_range: Vector2 = Vector2(-34.0, -14.0)
## 木の幹からこれ以上(m)離れた場所に置く
@export var min_tree_distance: float = 0.9

var _treasure: Treasure
var _since_found: float = 0.0
var _since_start: float = 0.0
var _random_time: float = 0.0
var _done: bool = false


func _ready() -> void:
	_random_time = randf_range(random_time_range.x, random_time_range.y)
	GameState.treasure_added.connect(func(_d: TreasureData) -> void: _since_found = 0.0)
	_spawn_treasure.call_deferred()


func _process(delta: float) -> void:
	if _done or _treasure == null or not GameState.running:
		return
	_since_found += delta
	_since_start += delta
	if _since_found >= lost_time or _since_start >= _random_time:
		_spawn_butterfly()


func _spawn_treasure() -> void:
	var data := _pick_data()
	if data == null:
		_done = true
		return
	_treasure = treasure_scene.instantiate() as Treasure
	_treasure.data = data
	_treasure.hidden_by_butterfly = true
	_treasure.position = _pick_hidden_spot()
	get_parent().add_child(_treasure)
	_treasure.discovered.connect(func(_d: TreasureData) -> void: _done = true)


## たるちゃんの少し前に向かって、画面の外(横の上の方)から飛んでくる
func _spawn_butterfly() -> void:
	_done = true
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null or not is_instance_valid(_treasure) or _treasure.is_found:
		return
	var forward := Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, player.global_rotation.y)
	var right := forward.cross(Vector3.UP)
	var side := 1.0 if randf() < 0.5 else -1.0
	var start := player.global_position + forward * 5.0 + right * side * 7.0 + Vector3(0.0, 2.5, 0.0)
	var butterfly := butterfly_scene.instantiate() as Butterfly
	get_parent().add_child(butterfly)
	butterfly.setup(_treasure, Butterfly.home_near(player), start)
	appeared.emit()


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
	# 最初は木から min_tree_distance 離れた場所を探し、見つからなければ余裕を小さくして探し直す
	for margin in [min_tree_distance, 0.3]:
		for attempt in 100:
			var z := randf_range(hidden_z_range.x, hidden_z_range.y)
			var side := -1.0 if randf() < 0.5 else 1.0
			spot = Vector3(ForestBuilder.path_x(z) + side * randf_range(hidden_offset.x, hidden_offset.y), 0.0, z)
			if builder == null or builder.is_clear(spot, margin):
				return spot
	push_warning("ButterflyEvent: 隠しいいものの置き場所が見つかりませんでした")
	return spot
