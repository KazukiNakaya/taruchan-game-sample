class_name Taruchan
extends CharacterBody3D
## たるちゃん本体。カメラの向き基準で移動し、移動方向へゆっくり体を向ける。

## 歩きの速度(m/s)。アニメの基準速度 0.32 m/s の約1.75倍
@export var walk_speed: float = 0.56
## 小走りの速度(m/s)
@export var run_speed: float = 1.12
@export var acceleration: float = 4.0
@export var deceleration: float = 6.0
## 体の向きを変える速さ(大きいほど素早く向く)
@export var turn_speed: float = 6.0
## 移動方向の基準にするカメラ(FollowCamera)
@export var camera: Node3D

## ジャンプの高さ(m)。体高 約0.4 m に対して控えめ
@export var jump_height: float = 0.35
## 空中での横移動のしやすさ(1 で地上と同じ)
@export_range(0.0, 1.0) var air_control: float = 0.6

## 発見したあと、掘る動作を続ける時間(秒)
@export var dig_time: float = 1.0

## おすわりで落ち着いているとき、においの届く半径にかける倍率
@export var sit_smell_scale: float = 1.5

const GRAVITY: float = 9.8

## 立ち止まっているとき、注目先が首の可動域を超えた分だけ体を向ける速さ
@export var look_turn_speed: float = 1.5

@onready var _animator: TaruchanAnimator = $Animator
@onready var _head_look: HeadLook = $HeadLook
@onready var _sniff: SniffSensor = $SniffSensor

var _tail: TailWag
var _tail_burst: float = 0.0


func _ready() -> void:
	_animator.setup($Model/AnimationPlayer)
	_head_look.setup(self, $Model, _sniff)
	_sniff.treasure_found.connect(_on_treasure_found)
	_tail = TailWag.new()
	_tail.name = "TailWag"
	($Model.find_child("Skeleton3D", true, false) as Skeleton3D).add_child(_tail)


## クンクン中、または掘っている最中(カメラが寄る合図)
func is_focusing() -> bool:
	return _sniff.is_sniffing or _animator.is_digging()


## おすわりで落ち着いている(ベンチでおさんぽを終えられる)
func is_seated() -> bool:
	return _animator.is_seated()


func _physics_process(delta: float) -> void:
	# クンクン中・掘っている最中はその場で止まる
	var busy := is_focusing() or _animator.is_sit_locked()
	_update_sit()
	var input := Vector2.ZERO
	if not busy:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _camera_relative(input)
	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target_velocity := direction * target_speed * minf(input.length(), 1.0)
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	if not is_on_floor():
		rate *= air_control
	horizontal = horizontal.move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor() and velocity.y <= 0.0:
		velocity.y = 0.0
		if Input.is_action_just_pressed("jump") and not busy:
			velocity.y = sqrt(2.0 * GRAVITY * jump_height)
			_animator.start_jump()
	else:
		velocity.y -= GRAVITY * delta

	if direction != Vector3.ZERO:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))
	elif _head_look.body_turn_hint > 0.0:
		# 左側の注目先は首だけでは届かないので、体ごと少し向ける
		rotation.y += _head_look.body_turn_hint * minf(look_turn_speed * delta, 1.0)

	move_and_slide()
	GameState.add_distance(horizontal.length() * delta)
	_animator.update(delta, is_on_floor(), horizontal.length(), Input.is_action_pressed("run"), _sniff.is_sniffing)
	_update_tail(delta, horizontal.length())


## 入力ベクトルをカメラの向き(水平成分のみ)基準のワールド方向に変換する
func _camera_relative(input: Vector2) -> Vector3:
	if input == Vector2.ZERO:
		return Vector3.ZERO
	var yaw := camera.global_rotation.y if camera else 0.0
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw).normalized()


## おすわりの切り替え(Ctrl / C / パッドY)。地上で、クンクン・掘る・ジャンプ中でなければ受け付ける
func _update_sit() -> void:
	if Input.is_action_just_pressed("sit") and is_on_floor() and not is_focusing() and not _animator.is_jumping():
		_animator.toggle_sit()
	_sniff.enabled = not _animator.is_sit_locked()
	_sniff.smell_scale = sit_smell_scale if _animator.is_seated() else 1.0


func _on_treasure_found(_data: TreasureData) -> void:
	_animator.start_dig(dig_time)
	_tail_burst = 1.5


## しっぽ振りの強さ・速さを、状態(待機/移動/におい/クンクン/発見)で決める
func _update_tail(delta: float, speed: float) -> void:
	_tail_burst = maxf(_tail_burst - delta, 0.0)
	var amplitude := 0.15
	var frequency := 1.5
	if speed > 0.05:
		amplitude = 0.22
		frequency = 2.5 if speed < run_speed * 0.8 else 4.5
	var nearest := _sniff.nearest
	if nearest:
		var d := nearest.global_position.distance_to(global_position)
		var closeness := clampf(1.0 - d / (nearest.data.smell_radius * _sniff.smell_scale), 0.0, 1.0)
		amplitude = lerpf(amplitude, 0.5, closeness)
		frequency = lerpf(frequency, 7.0, closeness)
	if _sniff.is_sniffing:
		amplitude = 0.45
		frequency = 6.0
	if _tail_burst > 0.0:
		amplitude = 0.6
		frequency = 8.0
	_tail.set_mood(amplitude, frequency)
