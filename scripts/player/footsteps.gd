class_name Footsteps
extends Node
## 足音。足元の地面(土/草/葉っぱ)で音を切り替え、移動速度に合わせた間隔で鳴らす。

## 歩きアニメの基準速度(m/s)で、1秒あたりに鳴らす足音の数
@export var steps_per_second_at_base: float = 2.0
@export var base_speed: float = 0.32
@export var min_speed: float = 0.05
@export var volume_db: float = -8.0

const SURFACES: Array[StringName] = [&"dirt", &"grass", &"leaves"]
const VARIANTS: int = 3

var _body: CharacterBody3D
var _player: AudioStreamPlayer3D
var _streams: Dictionary = {}  # 地面の種類 -> AudioStreamRandomizer
var _phase: float = 0.0


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_player = AudioStreamPlayer3D.new()
	_player.name = "FootstepPlayer"
	_player.volume_db = volume_db
	_player.bus = &"SFX"
	_player.unit_size = 3.0
	_body.add_child.call_deferred(_player)
	for surface in SURFACES:
		var randomizer := AudioStreamRandomizer.new()
		randomizer.random_pitch = 1.15
		randomizer.random_volume_offset_db = 2.0
		for i in VARIANTS:
			randomizer.add_stream(i, load("res://audio/footsteps/%s_%d.wav" % [surface, i + 1]))
		_streams[surface] = randomizer


func _physics_process(delta: float) -> void:
	var speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	if speed < min_speed or not _body.is_on_floor():
		_phase = 0.0
		return
	_phase += delta * steps_per_second_at_base * speed / base_speed
	if _phase >= 1.0:
		_phase -= 1.0
		_play()


func _play() -> void:
	if not _player.is_inside_tree():
		return
	_player.stream = _streams[_current_surface()]
	_player.play()


func _current_surface() -> StringName:
	var map := get_tree().get_first_node_in_group(&"surface_map")
	if map and map.has_method("surface_at"):
		return map.surface_at(_body.global_position)
	return &"grass"
