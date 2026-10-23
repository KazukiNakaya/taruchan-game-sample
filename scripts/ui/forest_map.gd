class_name ForestMap
extends Control
## 画面左上の全体マップ。回転させない固定表示で、開始(z=0)が下、ゴールが上。
## 小道・木・葉っぱだまり・ゴールと、自分の位置と向きを描く。
## 座って落ち着いている間だけ、いいもの(蝶々の隠しいいもの以外)の大体の位置をぼんやり出す。

## 1m あたりの画素数
@export var pixels_per_meter: float = 3.6
## マップに入れる範囲(ワールドの x と z)。z は小さいほど奥(ゴール側)
@export var world_x_range: Vector2 = Vector2(-15.0, 15.0)
@export var world_z_range: Vector2 = Vector2(-46.0, 6.0)
## ぼんやり表示: 本当の位置からずらす距離(m)と、もやの半径(m)
@export var blur_offset_range: Vector2 = Vector2(1.5, 3.0)
@export var blur_radius: float = 3.5

const BACKGROUND := Color(0.08, 0.12, 0.07, 0.55)
const FRAME := Color(1.0, 1.0, 1.0, 0.35)
const PATH_COLOR := Color(0.78, 0.62, 0.42, 0.9)
const TREE_COLOR := Color(0.18, 0.42, 0.2, 0.75)
const LEAF_COLOR := Color(0.75, 0.45, 0.2, 0.6)
const GOAL_COLOR := Color(1.0, 0.85, 0.3)
const PLAYER_COLOR := Color(1.0, 1.0, 1.0)
const HINT_COLOR := Color(1.0, 0.9, 0.45)

var _builder: ForestBuilder
var _player: Taruchan
var _goal: Node3D
var _hint_alpha: float = 0.0
var _offsets: Dictionary = {}  # Treasure -> ずらす量(Vector2, m)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = _map_size()


func _process(delta: float) -> void:
	if _builder == null or not is_instance_valid(_builder):
		_builder = get_tree().get_first_node_in_group(&"surface_map") as ForestBuilder
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Taruchan
	if _goal == null or not is_instance_valid(_goal):
		var stage := get_tree().current_scene
		_goal = stage.get_node_or_null("Goal") as Node3D if stage else null
	var seated := _player != null and _player.is_seated()
	_hint_alpha = move_toward(_hint_alpha, 1.0 if seated else 0.0, delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var size_px := _map_size()
	draw_rect(Rect2(Vector2.ZERO, size_px), BACKGROUND)
	if _builder:
		_draw_forest()
	if _hint_alpha > 0.0:
		_draw_hints()
	if _goal:
		var g := _to_map(_goal.global_position)
		draw_rect(Rect2(g - Vector2(5, 3), Vector2(10, 6)), GOAL_COLOR)
	if _player:
		_draw_player()
	draw_rect(Rect2(Vector2.ZERO, size_px), FRAME, false, 1.5)


func _draw_forest() -> void:
	for patch in _builder.leaf_patches():
		draw_circle(_to_map(Vector3(patch.x, 0.0, patch.y)), patch.z * pixels_per_meter, LEAF_COLOR)
	var points := PackedVector2Array()
	var z := world_z_range.y
	while z >= -_builder.length - 2.0:
		points.append(_to_map(Vector3(ForestBuilder.path_x(z), 0.0, z)))
		z -= 1.0
	draw_polyline(points, PATH_COLOR, _builder.path_half_width * 2.0 * pixels_per_meter)
	for tree in _builder.tree_positions():
		var p := _to_map(Vector3(tree.x, 0.0, tree.y))
		if Rect2(Vector2.ZERO, _map_size()).has_point(p):
			draw_circle(p, 2.0, TREE_COLOR)


## 座っている間の、いいもののぼんやりした位置(蝶々の隠しいいもの・見つけたものは出さない)
func _draw_hints() -> void:
	for node in get_tree().get_nodes_in_group(&"treasure"):
		var treasure := node as Treasure
		if treasure == null or treasure.is_found or treasure.hidden_by_butterfly:
			continue
		if not _offsets.has(treasure):
			var dist := randf_range(blur_offset_range.x, blur_offset_range.y)
			_offsets[treasure] = Vector2.from_angle(randf() * TAU) * dist
		var offset: Vector2 = _offsets[treasure]
		var center := _to_map(treasure.global_position + Vector3(offset.x, 0.0, offset.y))
		var radius := blur_radius * pixels_per_meter
		# 中心ほど濃い、輪郭のないもや
		for i in 6:
			var t := float(i) / 6.0
			var color := HINT_COLOR
			color.a = 0.09 * _hint_alpha
			draw_circle(center, radius * (1.0 - t * 0.8), color)


func _draw_player() -> void:
	var pos := _to_map(_player.global_position)
	var forward := Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, _player.global_rotation.y)
	var dir := Vector2(forward.x, forward.z).normalized()
	var side := Vector2(-dir.y, dir.x)
	var tip := pos + dir * 7.0
	var left := pos - dir * 4.0 + side * 4.5
	var right := pos - dir * 4.0 - side * 4.5
	draw_colored_polygon(PackedVector2Array([tip, left, right]), PLAYER_COLOR)
	draw_polyline(PackedVector2Array([tip, left, right, tip]), Color(0, 0, 0, 0.6), 1.0)


func _to_map(world: Vector3) -> Vector2:
	return Vector2((world.x - world_x_range.x) * pixels_per_meter, (world.z - world_z_range.x) * pixels_per_meter)


func _map_size() -> Vector2:
	return Vector2(world_x_range.y - world_x_range.x, world_z_range.y - world_z_range.x) * pixels_per_meter
