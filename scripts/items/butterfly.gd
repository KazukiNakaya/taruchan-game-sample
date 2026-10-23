class_name Butterfly
extends Node3D
## 蝶々。近づくとついてくるのを待ちながら、隠しいいものの場所へ案内する。
## 見た目はモデル(glb)。モデルが無い・読めないときは、仮の板2枚の羽ばたきになる。

enum State { WAIT, GUIDE, HOVER, LEAVE }

## 案内で飛ぶ速さ(m/s)。たるちゃんの小走り(1.12)より遅い
@export var guide_speed: float = 0.9
## この距離(m)までたるちゃんが近づくと、案内を始める
@export var notice_radius: float = 3.0
## 案内中、たるちゃんがこの距離(m)より遠いと、止まって待つ
@export var wait_radius: float = 2.5
## 羽ばたきの速さ(1秒あたりの往復回数)。1 で、1秒に1回ゆっくり羽ばたく
@export var flap_hz: float = 1.0
## 見やすいように、実寸(小さな犬に対して)より大きくしている倍率(仮の見た目用)
@export var size_scale: float = 1.2
@export var wing_color: Color = Color(0.98, 0.62, 0.15)
## 本番の蝶々のモデル(glb)。設定されていれば、仮の板2枚の代わりに使う。
## モデルに入っている羽ばたきアニメ(model_animation)を、ループ再生する
@export var model_scene: PackedScene
## 羽ばたきアニメの名前と、再生の速さ(1.0 で元のまま。元は約1秒に1回)
@export var model_animation: StringName = &"Take 001"
@export var model_animation_speed: float = 1.0
## モデルの中で隠すノードの名前(同じglbに入っている別の蝶々や、空のグループ)
@export var model_hidden_nodes: PackedStringArray = PackedStringArray()
## モデルの中心(体の位置)とみなすノードの名前。ここが蝶々の原点になる
@export var model_center_node: String = ""
## モデルの顔が向いている向き(度)。ゲームの前方(-Z)に合わせる回転(Y軸まわり)
@export var model_yaw_degrees: float = 0.0
## モデルの羽を広げたときの幅(m)
@export var model_wing_span: float = 0.18

var target: Treasure
var state: State = State.WAIT

var _home: Vector3
var _time: float = 0.0
var _flap_phase: float = 0.0
var _left_wing: Node3D  # 仮の見た目のときだけ使う
var _right_wing: Node3D
var _model_player: AnimationPlayer
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
	# 水平から少し下げた位置と、大きく持ち上げた位置の間を、なめらかに往復する
	if _left_wing:
		var flap := 0.35 + 0.65 * sin(_flap_phase)
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


## モデル(glb)の見た目を作る。羽ばたきは、モデルに入っているアニメを使う。
## 失敗したら false を返し、仮の見た目に戻る。
func _build_model_visual() -> bool:
	var model := model_scene.instantiate() as Node3D
	if model == null:
		return false
	for node_name in model_hidden_nodes:
		var hidden := model.find_child(node_name, true, false) as Node3D
		if hidden:
			hidden.visible = false

	var holder := Node3D.new()
	holder.rotation.y = deg_to_rad(model_yaw_degrees)
	add_child(holder)
	holder.add_child(model)

	var wing_width := _visible_width(model)
	if wing_width <= 0.001:
		holder.queue_free()
		return false
	var k := model_wing_span / wing_width
	model.scale = Vector3.ONE * k
	# 体の中心を、蝶々の原点に合わせる
	var center_node := model.find_child(model_center_node, true, false) as Node3D if model_center_node != "" else null
	var center := _visible_bounds(model, center_node).get_center()
	model.position = -(center * k)

	for node in model.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_model_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _model_player and _model_player.has_animation(model_animation):
		_model_player.get_animation(model_animation).loop_mode = Animation.LOOP_LINEAR
		_model_player.speed_scale = model_animation_speed
		_model_player.play(model_animation)
		# 複数の蝶々が同じ動きにならないように、再生位置をずらす
		_model_player.seek(randf() * _model_player.get_animation(model_animation).length, true)
	return true


## 見えているメッシュ全体の、横幅(元の単位)
func _visible_width(model: Node3D) -> float:
	return _visible_bounds(model, null).size.x


## 見えているメッシュの範囲(model の座標)。from_node を指定すると、その下だけで測る
func _visible_bounds(model: Node3D, from_node: Node3D) -> AABB:
	var root_node: Node = from_node if from_node else model
	var first := true
	var total := AABB()
	var model_inverse := model.global_transform.affine_inverse()
	for node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance.is_visible_in_tree():
			continue
		var box := model_inverse * (mesh_instance.global_transform * mesh_instance.get_aabb())
		total = box if first else total.merge(box)
		first = false
	return total
