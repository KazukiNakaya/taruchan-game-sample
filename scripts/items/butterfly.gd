class_name Butterfly
extends Node3D
## 蝶々。近づくとついてくるのを待ちながら、隠しいいものの場所へ案内する。
## 見た目と羽ばたきは仮(板2枚を動かしているだけ)。

enum State { WAIT, GUIDE, HOVER, LEAVE }

## 案内で飛ぶ速さ(m/s)。たるちゃんの小走り(1.12)より遅い
@export var guide_speed: float = 0.9
## この距離(m)までたるちゃんが近づくと、案内を始める
@export var notice_radius: float = 3.0
## 案内中、たるちゃんがこの距離(m)より遠いと、止まって待つ
@export var wait_radius: float = 2.5
@export var flap_hz: float = 11.0
## 見やすいように、実寸(小さな犬に対して)より大きくしている倍率(仮の見た目用)
@export var size_scale: float = 2.4
## 本番の蝶々のモデル(glb)。設定されていれば、仮の板2枚の代わりに使う。
## 羽は左右に分けて、胴体のつけ根を軸に羽ばたかせる(モデルの前が -Z、羽が ±X に広がる向き)
@export var model_scene: PackedScene
## モデルの羽を広げた幅(m)
@export var model_wing_span: float = 0.36
## モデル座標(元の単位)での、羽のつけ根(胴体の中心線)。モデルを差し替えたら合わせる
@export var model_hinge: Vector3 = Vector3(144.0, 24.0, 98.0)
## 胴体とみなす x の範囲(モデル座標)。この範囲に収まるメッシュは胴体、それより左右は羽
@export var model_body_x_range: Vector2 = Vector2(120.0, 170.0)
@export var wing_color: Color = Color(0.98, 0.62, 0.15)

var target: Treasure
var state: State = State.WAIT

var _home: Vector3
var _time: float = 0.0
var _flap_phase: float = 0.0
var _left_wing: Node3D
var _right_wing: Node3D
var _player: Node3D
var _leave_time: float = 0.0


## 案内先のいいもの、待つ場所、飛んでくる最初の位置を決める
func setup(target_treasure: Treasure, home: Vector3, start: Vector3) -> void:
	target = target_treasure
	_home = home
	global_position = start
	target.discovered.connect(_on_target_discovered)


## たるちゃんの少し前の、蝶々が待つ位置
static func home_near(player: Node3D) -> Vector3:
	var forward := Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, player.global_rotation.y)
	return player.global_position + forward * 2.5 + Vector3(0.0, 0.8, 0.0)


func _ready() -> void:
	add_to_group(&"look_target")
	_time = randf() * 10.0
	_build_visual()


func _process(delta: float) -> void:
	_time += delta
	_flap_phase += TAU * flap_hz * delta
	var flap := 0.25 + 0.75 * absf(sin(_flap_phase))
	_left_wing.rotation.z = flap
	_right_wing.rotation.z = -flap
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node3D

	var previous := global_position
	match state:
		State.WAIT:
			# 飛んできて、たるちゃんの少し前でひらひら待つ。離れていったら、また前に回り込む
			if _player and _player.global_position.distance_to(_home) > 5.0:
				_home = home_near(_player)
			global_position = global_position.lerp(_home + _wobble(0.5), 1.0 - exp(-1.2 * delta))
			if _player and _flat_distance(_player.global_position) < notice_radius and global_position.distance_to(_home) < 1.5:
				state = State.GUIDE
		State.GUIDE:
			_guide(delta)
		State.HOVER:
			var center := target.global_position + Vector3(0.0, 0.55, 0.0)
			var angle := _time * 1.6
			global_position = global_position.lerp(center + Vector3(cos(angle), 0.0, sin(angle)) * 0.25 + Vector3(0.0, sin(_time * 3.0) * 0.05, 0.0), 1.0 - exp(-4.0 * delta))
		State.LEAVE:
			_leave_time += delta
			global_position += Vector3(0.6, 0.9, -0.4) * delta
			scale = Vector3.ONE * maxf(1.0 - _leave_time / 3.0, 0.0)
			if _leave_time >= 3.0:
				queue_free()
	_face_movement(previous)


func _guide(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_start_leaving()
		return
	var goal := target.global_position + Vector3(0.0, 0.6, 0.0)
	var to_goal := goal - global_position
	if Vector2(to_goal.x, to_goal.z).length() < 0.3:
		state = State.HOVER
		return
	# たるちゃんが離れすぎているときは、その場でひらひらして待つ
	if _player and _flat_distance(_player.global_position) > wait_radius:
		global_position += _wobble(0.5) * delta * 0.6
		return
	global_position += to_goal.normalized() * guide_speed * delta
	global_position.y += sin(_time * 4.0) * 0.15 * delta


func _wobble(amount: float) -> Vector3:
	return Vector3(sin(_time * 0.9) * amount, 0.15 * sin(_time * 1.7), cos(_time * 0.7) * amount)


func _flat_distance(point: Vector3) -> float:
	var d := point - global_position
	return Vector2(d.x, d.z).length()


func _face_movement(previous: Vector3) -> void:
	var move := global_position - previous
	move.y = 0.0
	if move.length() > 0.0005:
		var target_yaw := atan2(-move.x, -move.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.15)


func _on_target_discovered(_data: TreasureData) -> void:
	_start_leaving()


func _start_leaving() -> void:
	if state == State.LEAVE:
		return
	state = State.LEAVE
	remove_from_group(&"look_target")


func _build_visual() -> void:
	if model_scene and _build_model_visual():
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = wing_color
	material.emission_enabled = true
	material.emission = wing_color
	material.emission_energy_multiplier = 0.3
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.008 * size_scale
	capsule.height = 0.06 * size_scale
	body.mesh = capsule
	body.rotation.x = PI / 2.0
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.15, 0.1, 0.08)
	body.material_override = body_material
	add_child(body)

	_left_wing = _make_wing(material, 1.0)
	_right_wing = _make_wing(material, -1.0)


func _make_wing(material: Material, side: float) -> Node3D:
	var pivot := Node3D.new()
	add_child(pivot)
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.07, 0.08) * size_scale
	quad.mesh = mesh
	quad.material_override = material
	quad.rotation.x = -PI / 2.0  # 板を水平に寝かせる
	quad.position = Vector3(side * 0.036 * size_scale, 0.0, 0.0)
	pivot.add_child(quad)
	return pivot


## モデル(glb)の見た目を作る。羽を左右のグループに分けて、つけ根の軸で動かせるようにする。
## 失敗したら false を返し、仮の見た目に戻る。
func _build_model_visual() -> bool:
	var model := model_scene.instantiate() as Node3D
	if model == null:
		return false
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		model.queue_free()
		return false

	var root := Node3D.new()
	var model_size := _model_width(model)
	var k := model_wing_span / model_size
	root.scale = Vector3.ONE * k
	root.position = -model_hinge * k
	add_child(root)
	root.add_child(model)

	# 羽ばたきの軸(つけ根)。root の座標では model_hinge の位置
	var plus_pivot := Node3D.new()  # +X 側の羽
	var minus_pivot := Node3D.new()  # -X 側の羽
	plus_pivot.position = model_hinge
	minus_pivot.position = model_hinge
	root.add_child(plus_pivot)
	root.add_child(minus_pivot)

	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var box := mesh_instance.global_transform * mesh_instance.get_aabb()
		# global_transform は model が root の子になった今の座標。model 座標に戻すため root の逆変換をかける
		var local_box := root.global_transform.affine_inverse() * box
		var in_body := local_box.position.x >= model_body_x_range.x and local_box.end.x <= model_body_x_range.y
		if in_body:
			continue
		mesh_instance.reparent(plus_pivot if local_box.get_center().x > model_hinge.x else minus_pivot, true)
	_left_wing = plus_pivot
	_right_wing = minus_pivot
	return true


## モデル全体の、羽を広げた方向(x)の幅(元の単位)
func _model_width(model: Node3D) -> float:
	var first := true
	var total := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var box := mesh_instance.transform * mesh_instance.get_aabb()
		var parent := mesh_instance.get_parent()
		while parent and parent != model:
			box = (parent as Node3D).transform * box
			parent = parent.get_parent()
		total = box if first else total.merge(box)
		first = false
	return maxf(total.size.x, 0.001)
