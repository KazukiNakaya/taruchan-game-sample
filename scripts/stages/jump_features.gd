class_name JumpFeatures
extends Node3D
## ジャンプを使う場所(仮のローポリ)。
## - 倒木: 小道を横切る(高さ約0.3m)。ジャンプで乗って越える。端を回り込んでもよい
## - 切り株・平たい岩: 高さ約0.3m。いくつかの上に いいものを置く。ジャンプで乗らないとクンクンできない
## 置いたものは ForestBuilder に「ふさがっている場所」として伝え、ほかの置き物と重ならないようにする。

@export var treasure_scene: PackedScene
@export var random_seed: int = 11
## 倒木を置く位置(z)
@export var log_z: PackedFloat32Array = PackedFloat32Array([-11.0, -29.0])
@export var log_length: float = 3.2
@export var log_radius: float = 0.13
## 切り株・岩の数と、そのうち上に いいものを置く数
@export var perch_count: int = 4
@export var perch_treasure_count: int = 2
@export var perch_height: float = 0.28
@export var perch_z_range: Vector2 = Vector2(-37.0, -5.0)
## 切り株・岩を置く、小道の中心線からの距離(m)
@export var perch_offset: Vector2 = Vector2(1.8, 2.6)

const WOOD := Color(0.42, 0.28, 0.17)
const WOOD_TOP := Color(0.66, 0.5, 0.32)
const STONE := Color(0.5, 0.5, 0.52)

var _rng := RandomNumberGenerator.new()
var _logs: Array[PackedVector2Array] = []  # 両端(x, z)
var _perches: Array[Vector3] = []  # x, z, 半径
var _perch_tops: Array[Vector3] = []  # 上面の中心(いいもの用)


func _ready() -> void:
	add_to_group(&"jump_features")
	_rng.seed = random_seed
	var builder := get_tree().get_first_node_in_group(&"surface_map") as ForestBuilder
	if builder == null:
		push_warning("JumpFeatures: ForestBuilder が見つかりません")
		return
	for z in log_z:
		_build_log(builder, z)
	_build_perches(builder)
	_spawn_perch_treasures.call_deferred()


## マップ表示用: 倒木の両端
func logs() -> Array[PackedVector2Array]:
	return _logs


## マップ表示用: 切り株・岩(x, z, 半径)
func perches() -> Array[Vector3]:
	return _perches


func _build_log(builder: ForestBuilder, z: float) -> void:
	var center := Vector3(ForestBuilder.path_x(z), log_radius, z)
	# 小道の向きに直角に置く
	var slope := 3.5 / 9.0 * cos(z / 9.0)  # path_x の z 微分
	var across := Vector3(1.0, 0.0, -slope).normalized()
	var basis := Basis(Vector3.UP, across, Vector3.UP.cross(across))

	var mesh := CylinderMesh.new()
	mesh.top_radius = log_radius
	mesh.bottom_radius = log_radius
	mesh.height = log_length
	mesh.radial_segments = 8
	mesh.rings = 1
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(WOOD)
	visual.transform = Transform3D(basis, center)
	add_child(visual)

	# 当たり判定は箱(上に乗れて、転がり落ちない)
	var body := StaticBody3D.new()
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(log_radius * 2.0, log_length, log_radius * 2.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.transform = Transform3D(basis, center)
	body.add_child(col)

	var half := across * log_length * 0.5
	_logs.append(PackedVector2Array([Vector2(center.x - half.x, z - half.z), Vector2(center.x + half.x, z + half.z)]))
	for t: float in [-0.4, -0.2, 0.0, 0.2, 0.4]:
		var p := center + across * log_length * t
		builder.add_blocker(Vector2(p.x, p.z), 0.6)


func _build_perches(builder: ForestBuilder) -> void:
	var spawn_points := get_tree().get_nodes_in_group(&"spawn_points")
	for i in perch_count:
		var spot := Vector3.ZERO
		var found := false
		for attempt in 60:
			var z := _rng.randf_range(perch_z_range.x, perch_z_range.y)
			var side := -1.0 if _rng.randf() < 0.5 else 1.0
			spot = Vector3(ForestBuilder.path_x(z) + side * _rng.randf_range(perch_offset.x, perch_offset.y), 0.0, z)
			if builder.is_clear(spot, 1.0) and _far_from_spawn_points(spot, spawn_points, 1.2):
				found = true
				break
		if not found:
			continue
		var is_stump := i % 2 == 0
		var radius := 0.3 if is_stump else 0.38
		_build_perch(spot, radius, is_stump)
		_perches.append(Vector3(spot.x, spot.z, radius))
		_perch_tops.append(spot + Vector3(0.0, perch_height, 0.0))
		builder.add_blocker(Vector2(spot.x, spot.z), radius + 0.4)


func _build_perch(spot: Vector3, radius: float, is_stump: bool) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * (1.12 if is_stump else 1.2)
	mesh.height = perch_height
	mesh.radial_segments = 10 if is_stump else 7
	mesh.rings = 1
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(WOOD if is_stump else STONE)
	visual.position = spot + Vector3(0.0, perch_height * 0.5, 0.0)
	visual.rotation.y = _rng.randf() * TAU
	add_child(visual)
	if is_stump:
		# 切り口(年輪の明るい面)
		var top := MeshInstance3D.new()
		var top_mesh := CylinderMesh.new()
		top_mesh.top_radius = radius * 0.92
		top_mesh.bottom_radius = radius * 0.92
		top_mesh.height = 0.005
		top_mesh.radial_segments = 10
		top_mesh.rings = 1
		top.mesh = top_mesh
		top.material_override = _material(WOOD_TOP)
		top.position = spot + Vector3(0.0, perch_height + 0.003, 0.0)
		add_child(top)

	var body := StaticBody3D.new()
	add_child(body)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = perch_height
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = spot + Vector3(0.0, perch_height * 0.5, 0.0)
	body.add_child(col)


## いくつかの切り株・岩の上に いいものを置く(地面からは届かない)
func _spawn_perch_treasures() -> void:
	var tops := _perch_tops.duplicate()
	tops.shuffle()
	for i in mini(perch_treasure_count, tops.size()):
		var treasure := treasure_scene.instantiate() as Treasure
		treasure.data = TreasureSpawner.pick_weighted()
		treasure.position = tops[i]
		get_parent().add_child(treasure)


func _far_from_spawn_points(spot: Vector3, points: Array[Node], min_dist: float) -> bool:
	for p in points:
		var n := p as Node3D
		if n and Vector2(n.global_position.x - spot.x, n.global_position.z - spot.z).length() < min_dist:
			return false
	return true


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat
