class_name HeadLook
extends Node
## 首の自動追従。注目ターゲット(Marker3D)をゆっくり動かし、LookAtModifier3D で head/chest をそちらへ向ける。
##
## 注目先の優先度: 1. SniffSensor が教えるにおいの届く一番近いいいもの / 2. なければ「きょろきょろ」。
## 向きは常にたるちゃんのローカル座標(前方は -Z、左は -X)で補間するので、体が回ってもついてくる。

## 首(head)の可動域: 右方向の最大角(度)
@export var head_right_limit_deg: float = 45.0
## 首(head)の可動域: 左方向の最大角(度)。モデルの顔が右にねじれているので小さめ
@export var head_left_limit_deg: float = 20.0
@export var head_up_limit_deg: float = 35.0
@export var head_down_limit_deg: float = 45.0
## 胸(chest)に配分する割合(首 7 : 胸 3)
@export_range(0.0, 1.0) var chest_ratio: float = 0.3
## 注目先へ向くときの追従の速さ(小さいほどゆっくり)
@export var look_speed: float = 3.0
## 正面へ戻るときの追従の速さ
@export var return_speed: float = 1.8
## きょろきょろの間隔(秒)
@export var wander_interval: Vector2 = Vector2(2.5, 5.0)
## きょろきょろの向き(度、右が負・左が正)
@export var wander_yaw_range_deg: Vector2 = Vector2(-40.0, 20.0)
## 注目点の高さ(m)。たるちゃんの目の高さ付近
@export var look_height: float = 0.3

## 左の可動域を超える注目先があるとき、体を向けたい角度(ラジアン、左が正)。0 なら不要
var body_turn_hint: float = 0.0

var _body: Node3D
var _sensor: SniffSensor
var _marker: Marker3D
var _local_goal: Vector3
var _local_pos: Vector3
var _wander_timer: float = 0.0
var _has_target: bool = false


func setup(body: Node3D, model: Node3D, sensor: SniffSensor) -> void:
	_body = body
	_sensor = sensor
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	assert(skeleton != null, "Skeleton3D が見つかりません")

	_marker = Marker3D.new()
	_marker.name = "LookTarget"
	_marker.top_level = true
	body.add_child(_marker)

	# 胸 → 首の順に処理する(首が胸の回転を受けたうえで向きを補正する)
	_add_modifier(skeleton, &"chest", chest_ratio)
	_add_modifier(skeleton, &"head", 1.0)

	_local_goal = Vector3(0.0, look_height, -2.0)
	_local_pos = _local_goal


func _physics_process(delta: float) -> void:
	if _body == null:
		return
	_update_goal(delta)
	var speed := look_speed if _has_target else return_speed
	_local_pos = _local_pos.lerp(_local_goal, 1.0 - exp(-speed * delta))
	_marker.global_position = _body.to_global(_local_pos)
	body_turn_hint = _calc_body_turn_hint()


func _update_goal(delta: float) -> void:
	var target: Node3D = _sensor.nearest
	_has_target = target != null
	if _has_target:
		_local_goal = _body.to_local(target.global_position)
		return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(wander_interval.x, wander_interval.y)
		_local_goal = _pick_wander_point()


func _pick_wander_point() -> Vector3:
	# 4割は正面を向く。それ以外は可動域の中のランダムな方向
	var yaw := 0.0
	if randf() > 0.4:
		yaw = deg_to_rad(randf_range(wander_yaw_range_deg.x, wander_yaw_range_deg.y))
	var dist := 2.0
	return Vector3(-sin(yaw) * dist, look_height + randf_range(-0.1, 0.1), -cos(yaw) * dist)


## 左の可動域を超えた分だけ、体を向けてほしい角度を返す
func _calc_body_turn_hint() -> float:
	if not _has_target:
		return 0.0
	var yaw := atan2(-_local_goal.x, -_local_goal.z)  # 左が正
	var limit := deg_to_rad(head_left_limit_deg)
	return maxf(yaw - limit, 0.0)


func _add_modifier(skeleton: Skeleton3D, bone: StringName, influence: float) -> void:
	var mod := LookAtModifier3D.new()
	mod.name = "LookAt_" + String(bone)
	skeleton.add_child(mod)
	mod.bone_name = bone
	mod.target_node = mod.get_path_to(_marker)
	mod.forward_axis = SkeletonModifier3D.BONE_AXIS_PLUS_Y
	mod.primary_rotation_axis = Vector3.AXIS_Z
	mod.influence = influence
	mod.use_angle_limitation = true
	mod.symmetry_limitation = false
	mod.primary_positive_limit_angle = deg_to_rad(head_left_limit_deg)
	mod.primary_negative_limit_angle = deg_to_rad(head_right_limit_deg)
	mod.secondary_positive_limit_angle = deg_to_rad(head_up_limit_deg)
	mod.secondary_negative_limit_angle = deg_to_rad(head_down_limit_deg)
