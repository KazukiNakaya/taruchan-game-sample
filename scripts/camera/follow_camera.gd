class_name FollowCamera
extends Node3D
## たるちゃんを遅れて追従する三人称カメラ。マウス/右スティックで回転する。

@export var target: Node3D
## 追従の速さ(大きいほどきびきび追う)
@export var follow_speed: float = 8.0
## 注視点の高さオフセット(m)
@export var height_offset: float = 0.3
@export var mouse_sensitivity: float = 0.003
@export var stick_sensitivity: float = 2.5
@export var min_pitch_deg: float = -60.0
@export var max_pitch_deg: float = 30.0

var _yaw: float = 0.0
var _pitch: float = deg_to_rad(-15.0)


func _ready() -> void:
	top_level = true
	if target:
		global_position = target.global_position + Vector3.UP * height_offset
		_yaw = target.global_rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_rotation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity


func _process(delta: float) -> void:
	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	_yaw -= stick.x * stick_sensitivity * delta
	_pitch -= stick.y * stick_sensitivity * delta
	_apply_rotation()
	if target:
		var goal := target.global_position + Vector3.UP * height_offset
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))


func _apply_rotation() -> void:
	_pitch = clampf(_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	global_rotation = Vector3(_pitch, _yaw, 0.0)
