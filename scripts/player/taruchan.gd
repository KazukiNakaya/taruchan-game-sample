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

## 歩きアニメが足滑りしない速度(m/s)
const ANIM_BASE_SPEED: float = 0.32
const GRAVITY: float = 9.8
const WALK_ANIM: StringName = &"walk"

## 立ち止まっているとき、注目先が首の可動域を超えた分だけ体を向ける速さ
@export var look_turn_speed: float = 1.5

@onready var _anim: AnimationPlayer = $Model/AnimationPlayer
@onready var _head_look: HeadLook = $HeadLook
@onready var _sniff: SniffSensor = $SniffSensor


func _ready() -> void:
	_anim.play(WALK_ANIM)
	_anim.speed_scale = 0.0
	_head_look.setup(self, $Model, _sniff)


func _physics_process(delta: float) -> void:
	# クンクン中はその場で止まる
	var input := Vector2.ZERO
	if not _sniff.is_sniffing:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _camera_relative(input)
	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target_velocity := direction * target_speed * minf(input.length(), 1.0)
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	horizontal = horizontal.move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta

	if direction != Vector3.ZERO:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))
	elif _head_look.body_turn_hint > 0.0:
		# 左側の注目先は首だけでは届かないので、体ごと少し向ける
		rotation.y += _head_look.body_turn_hint * minf(look_turn_speed * delta, 1.0)

	move_and_slide()
	GameState.add_distance(horizontal.length() * delta)
	_update_animation(horizontal.length())


## 入力ベクトルをカメラの向き(水平成分のみ)基準のワールド方向に変換する
func _camera_relative(input: Vector2) -> Vector3:
	if input == Vector2.ZERO:
		return Vector3.ZERO
	var yaw := camera.global_rotation.y if camera else 0.0
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw).normalized()


## 移動速度に合わせて歩きアニメの再生速度を決める(止まったら一時停止)
func _update_animation(speed: float) -> void:
	_anim.speed_scale = speed / ANIM_BASE_SPEED
