class_name ForestBuilder
extends Node3D
## 森の小道の見た目と当たり判定を、起動時に生成する(仮のローポリ。木・岩・草は後でglbに差し替える)。
## 小道は z=0(入口)から z=-length(ゴール)へ、ゆるく蛇行する。
## 地面もここで作る。小川(浅い溝)は z=stream_z で森を横切る。

@export var random_seed: int = 7
## 小道の長さ(m)。歩いて約1分
@export var length: float = 40.0
## 小道の半幅(m)
@export var path_half_width: float = 1.2
@export var tree_count: int = 80
@export var rock_count: int = 14
@export var grass_count: int = 750
@export var leaf_patch_count: int = 4
## 小川: 森を横切る位置(z)、幅、深さ(m)。岸は垂直で、歩いて渡れない(跳んで越える)。
## 落ちても浅い(深さ < ジャンプの高さ)ので、跳べば どちらの岸にも上がれる
@export var stream_z: float = -20.0
@export var stream_width: float = 0.6
@export var stream_depth: float = 0.15

const WALL_X: float = 19.0
const TREE_MIN_DIST: float = 2.8
const TREE_MAX_DIST: float = 12.0
const GROUND_HALF_WIDTH: float = 22.0
const GROUND_COLOR := Color(0.3, 0.45, 0.22)

var _rng := RandomNumberGenerator.new()
var _leaf_patches: Array[Vector3] = []  # x, z, 半径
var _tree_positions: PackedVector2Array = PackedVector2Array()  # x, z
var _blockers: Array[Vector3] = []  # x, z, 半径(倒木・切り株など、後から置いたもの)


## 小道の中心線の x 座標
static func path_x(z: float) -> float:
	return 3.5 * sin(z / 9.0)


func _ready() -> void:
	add_to_group(&"surface_map")
	_rng.seed = random_seed
	_build_ground()
	_build_water()
	_build_path()
	_build_leaf_patches()
	_build_trees()
	_build_rocks()
	_build_grass()
	_build_walls()


## 木の位置(x, z)の一覧(マップ表示用)
func tree_positions() -> PackedVector2Array:
	return _tree_positions


## 葉っぱだまり(x, z, 半径)の一覧(マップ表示用)
func leaf_patches() -> Array[Vector3]:
	return _leaf_patches


## 一番近い木の幹までの距離(m)。置き物が木に重ならないかの判定に使う
func min_tree_distance(pos: Vector3) -> float:
	var best := INF
	for tree in _tree_positions:
		best = minf(best, Vector2(pos.x, pos.z).distance_to(tree))
	return best


## 地面の高さ(m)。小川の溝だけ低い
func ground_height(z: float) -> float:
	return -stream_depth if absf(z - stream_z) < stream_half_width() else 0.0


## 小川の幅の半分(m)
func stream_half_width() -> float:
	return stream_width * 0.5


## 小川にかからないか(margin: 余裕 m)
func is_away_from_stream(z: float, margin: float) -> bool:
	return absf(z - stream_z) > stream_half_width() + margin


## 後から置いたもの(倒木・切り株など)の場所を登録する。ほかの置き物がそこを避ける
func add_blocker(pos: Vector2, radius: float) -> void:
	_blockers.append(Vector3(pos.x, pos.y, radius))


## 置き物を置いてよい場所か(木・登録済みの置き物・小川から margin m 以上離れている)
func is_clear(pos: Vector3, margin: float) -> bool:
	if min_tree_distance(pos) <= margin or not is_away_from_stream(pos.z, margin):
		return false
	for b in _blockers:
		if Vector2(pos.x - b.x, pos.z - b.y).length() <= b.z + margin * 0.5:
			return false
	return true


## 足元の地面の種類(足音の切り替え用): water / dirt / grass / leaves
func surface_at(pos: Vector3) -> StringName:
	if absf(pos.z - stream_z) < stream_half_width():
		return &"water"
	for patch in _leaf_patches:
		if Vector2(pos.x - patch.x, pos.z - patch.y).length() <= patch.z:
			return &"leaves"
	if absf(pos.x - path_x(pos.z)) <= path_half_width:
		return &"dirt"
	return &"grass"


func _build_path() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := _profile(6.0, -length - 6.0, 1.0)
	for i in profile.size() - 1:
		var z := profile[i].x
		var z2 := profile[i + 1].x
		var y := profile[i].y + 0.01
		var y2 := profile[i + 1].y + 0.01
		var a := Vector3(path_x(z) - path_half_width, y, z)
		var b := Vector3(path_x(z) + path_half_width, y, z)
		var c := Vector3(path_x(z2) - path_half_width, y2, z2)
		var d := Vector3(path_x(z2) + path_half_width, y2, z2)
		for v in [a, c, b, b, c, d]:
			st.add_vertex(v)
	st.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	instance.material_override = _flat_material(Color(0.55, 0.42, 0.28))
	add_child(instance)


func _build_leaf_patches() -> void:
	for i in leaf_patch_count:
		var z := -8.0 - (length - 16.0) * (float(i) + _rng.randf()) / leaf_patch_count
		var x := path_x(z) + _rng.randf_range(-1.5, 1.5)
		var radius := _rng.randf_range(0.9, 1.6)
		if not is_away_from_stream(z, radius + 0.3):
			z += radius + stream_half_width() + 1.0
		_leaf_patches.append(Vector3(x, z, radius))
		var disc := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = 0.01
		mesh.radial_segments = 16
		mesh.rings = 1
		disc.mesh = mesh
		disc.material_override = _flat_material(Color(0.5, 0.32, 0.14))
		disc.position = Vector3(x, 0.02, z)
		add_child(disc)


func _build_trees() -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.8
	trunk_mesh.bottom_radius = 1.0
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 6
	trunk_mesh.rings = 1
	var canopy_mesh := CylinderMesh.new()
	canopy_mesh.top_radius = 0.0
	canopy_mesh.bottom_radius = 1.0
	canopy_mesh.height = 1.0
	canopy_mesh.radial_segments = 7
	canopy_mesh.rings = 1

	var trunks := _multimesh(trunk_mesh, tree_count, _flat_material(Color.WHITE, true))
	var canopies := _multimesh(canopy_mesh, tree_count * 2, _flat_material(Color.WHITE, true))
	var body := StaticBody3D.new()
	body.name = "TreeColliders"
	add_child(body)

	for i in tree_count:
		var z := _rng.randf_range(-length - 12.0, 10.0)
		while not is_away_from_stream(z, 0.6):
			z = _rng.randf_range(-length - 12.0, 10.0)
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var x := path_x(z) + side * _rng.randf_range(TREE_MIN_DIST, TREE_MAX_DIST)
		var height := _rng.randf_range(3.0, 5.0)
		var radius := _rng.randf_range(0.12, 0.2)
		_tree_positions.append(Vector2(x, z))

		var trunk_xf := Transform3D(Basis.from_scale(Vector3(radius, height * 0.5, radius)), Vector3(x, height * 0.25, z))
		trunks.multimesh.set_instance_transform(i, trunk_xf)
		trunks.multimesh.set_instance_color(i, Color(0.35, 0.24, 0.16).lerp(Color(0.25, 0.18, 0.12), _rng.randf()))

		var green := Color(0.08, 0.26, 0.1).lerp(Color(0.16, 0.38, 0.12), _rng.randf())
		for layer in 2:
			var layer_h := height * (0.55 - 0.15 * layer)
			var layer_r := (1.3 - 0.35 * layer) * _rng.randf_range(0.9, 1.15)
			var y := height * (0.35 + 0.28 * layer) + layer_h * 0.5
			var canopy_xf := Transform3D(Basis.from_scale(Vector3(layer_r, layer_h, layer_r)), Vector3(x, y, z))
			canopies.multimesh.set_instance_transform(i * 2 + layer, canopy_xf)
			canopies.multimesh.set_instance_color(i * 2 + layer, green)

		var shape := CylinderShape3D.new()
		shape.radius = radius * 1.1
		shape.height = height * 0.5
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = Vector3(x, height * 0.25, z)
		body.add_child(col)


func _build_rocks() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var rocks := _multimesh(mesh, rock_count, _flat_material(Color.WHITE, true))
	var body := StaticBody3D.new()
	body.name = "RockColliders"
	add_child(body)
	for i in rock_count:
		var z := _rng.randf_range(-length, -4.0)
		while not is_away_from_stream(z, 0.8):
			z = _rng.randf_range(-length, -4.0)
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var x := path_x(z) + side * _rng.randf_range(2.0, 9.0)
		var s := _rng.randf_range(0.25, 0.7)
		var xf := Transform3D(Basis.from_scale(Vector3(s, s * 0.6, s * 0.85)).rotated(Vector3.UP, _rng.randf() * TAU), Vector3(x, s * 0.2, z))
		rocks.multimesh.set_instance_transform(i, xf)
		var g := _rng.randf_range(0.42, 0.58)
		rocks.multimesh.set_instance_color(i, Color(g, g, g * 1.04))
		var shape := SphereShape3D.new()
		shape.radius = s * 0.5
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = Vector3(x, s * 0.2, z)
		body.add_child(col)


func _build_grass() -> void:
	var tuft := _make_grass_tuft()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	var grass := _multimesh(tuft, grass_count, mat)
	for i in grass_count:
		var z := _rng.randf_range(-length - 6.0, 6.0)
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var off := path_half_width * 0.85 + _rng.randf_range(0.0, 9.0)
		var x := path_x(z) + side * off
		var s := _rng.randf_range(0.7, 1.5)
		if not is_away_from_stream(z, 0.1):
			s = 0.0  # 小川の中には草を生やさない
		var xf := Transform3D(Basis.from_scale(Vector3(s, s, s)).rotated(Vector3.UP, _rng.randf() * TAU), Vector3(x, 0.0, z))
		grass.multimesh.set_instance_transform(i, xf)
		grass.multimesh.set_instance_color(i, Color(0.85, 0.95, 0.85).lerp(Color.WHITE, _rng.randf()))


func _make_grass_tuft() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := Color(0.16, 0.34, 0.12)
	var tip := Color(0.5, 0.72, 0.28)
	for blade in 5:
		var angle := TAU * blade / 5.0
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var side := dir.cross(Vector3.UP) * 0.03
		var lean := dir * 0.06
		var top := Vector3(0.0, 0.22 + 0.04 * (blade % 2), 0.0) + lean
		var root := dir * 0.04
		st.set_color(base)
		st.add_vertex(root - side)
		st.set_color(base)
		st.add_vertex(root + side)
		st.set_color(tip)
		st.add_vertex(top + root)
	st.generate_normals()
	return st.commit()


## 地面(小川の溝つき)の見た目と当たり判定
func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := _profile(12.0, -length - 12.0, 2.0)
	for i in profile.size() - 1:
		var a := Vector3(-GROUND_HALF_WIDTH, profile[i].y, profile[i].x)
		var b := Vector3(GROUND_HALF_WIDTH, profile[i].y, profile[i].x)
		var c := Vector3(-GROUND_HALF_WIDTH, profile[i + 1].y, profile[i + 1].x)
		var d := Vector3(GROUND_HALF_WIDTH, profile[i + 1].y, profile[i + 1].x)
		for v in [a, c, b, b, c, d]:
			st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()
	var instance := MeshInstance3D.new()
	instance.name = "Ground"
	instance.mesh = mesh
	instance.material_override = _flat_material(GROUND_COLOR)
	add_child(instance)
	var body := StaticBody3D.new()
	body.name = "GroundCollider"
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = true  # 溝の垂直な岸も、どちらから当たっても止める
	col.shape = shape
	body.add_child(col)


## 小川の水面(水色の半透明。足が半分浸かるくらいの浅さ)
func _build_water() -> void:
	var water := MeshInstance3D.new()
	water.name = "Water"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(GROUND_HALF_WIDTH * 2.0, stream_width - 0.02)
	water.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.8, 0.95, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic_specular = 0.8
	water.material_override = mat
	water.position = Vector3(0.0, -stream_depth * 0.35, stream_z)
	add_child(water)


## 地面の断面: (z, 高さ)の並び(奥ほど z が小さい)。小川の岸は同じ z に高さ違いの点を2つ置いて、垂直な壁にする
func _profile(z_start: float, z_end: float, step: float) -> Array[Vector2]:
	var half := stream_half_width()
	var points: Array = []  # [z, 高さ, 同じ z のときの順番]
	var z := z_start
	while z > z_end:
		if absf(z - stream_z) > half + 0.001:
			points.append([z, 0.0, 0])
		z -= step
	points.append([z_end, 0.0, 0])
	points.append([stream_z + half, 0.0, 0])
	points.append([stream_z + half, -stream_depth, 1])
	points.append([stream_z - half, -stream_depth, 0])
	points.append([stream_z - half, 0.0, 1])
	points.sort_custom(func(a: Array, b: Array) -> bool:
		if absf(a[0] - b[0]) > 0.0001:
			return a[0] > b[0]
		return a[2] < b[2])
	var result: Array[Vector2] = []
	for p in points:
		result.append(Vector2(p[0], p[1]))
	return result


func _build_walls() -> void:
	# 森の外へ出られないように、目に見えない壁で囲う
	var body := StaticBody3D.new()
	body.name = "Walls"
	add_child(body)
	var z_min := -length - 10.0
	var z_max := 10.0
	var z_mid := (z_min + z_max) * 0.5
	var z_len := z_max - z_min
	for wall in [
		[Vector3(-WALL_X, 2.0, z_mid), Vector3(1.0, 4.0, z_len)],
		[Vector3(WALL_X, 2.0, z_mid), Vector3(1.0, 4.0, z_len)],
		[Vector3(0.0, 2.0, z_min), Vector3(WALL_X * 2.0, 4.0, 1.0)],
		[Vector3(0.0, 2.0, z_max), Vector3(WALL_X * 2.0, 4.0, 1.0)],
	]:
		var shape := BoxShape3D.new()
		shape.size = wall[1]
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = wall[0]
		body.add_child(col)


func _multimesh(mesh: Mesh, count: int, material: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = mm
	instance.material_override = material
	add_child(instance)
	return instance


func _flat_material(color: Color, use_vertex_color: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.vertex_color_use_as_albedo = use_vertex_color
	mat.roughness = 1.0
	return mat
