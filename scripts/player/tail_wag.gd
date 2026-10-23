class_name TailWag
extends SkeletonModifier3D
## しっぽ振り。アニメの上に、しっぽのボーンを世界の上方向まわりに左右へ揺らす。
## 強さ(amplitude)と速さ(frequency)を set_mood() で指定すると、なめらかに追従する。

const TAIL_BONES: Array[StringName] = [&"tail_1", &"tail_2", &"tail_3"]

## 先端ほど遅れて揺れる位相のずれ(ラジアン)
@export var phase_lag: float = 0.7
## 先端ほど大きく揺れる倍率(1 より大きいと先に行くほど振れ幅が増える)
@export var tip_gain: float = 1.4
## 強さ(amplitude)に掛ける倍率。しっぽが短いので、見た目に出るよう大きめにしている
@export var gain: float = 2.0
## 強さ・速さが目標に近づく速さ
@export var smoothing: float = 4.0

var _bones: PackedInt32Array = PackedInt32Array()
var _axes: PackedVector3Array = PackedVector3Array()  # 各ボーンのローカル座標での「世界の上」
var _amplitude: float = 0.15
var _frequency: float = 1.5
var _target_amplitude: float = 0.15
var _target_frequency: float = 1.5
var _phase: float = 0.0
var _last_usec: int = 0


func _ready() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for bone_name in TAIL_BONES:
		var bone := skeleton.find_bone(bone_name)
		if bone < 0:
			push_warning("しっぽのボーンが見つかりません: %s" % bone_name)
			continue
		_bones.append(bone)
		var rest := skeleton.get_bone_global_rest(bone)
		_axes.append((rest.basis.inverse() * Vector3.UP).normalized())


## 強さ(ラジアン、ボーン1本ぶんの最大の振れ)と、速さ(1秒あたりの往復回数)
func set_mood(amplitude: float, frequency: float) -> void:
	_target_amplitude = amplitude
	_target_frequency = frequency


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or _bones.is_empty():
		return
	var now := Time.get_ticks_usec()
	var delta := minf((now - _last_usec) / 1000000.0, 0.1) if _last_usec > 0 else 0.0
	_last_usec = now
	var weight := 1.0 - exp(-smoothing * delta)
	_amplitude = lerpf(_amplitude, _target_amplitude, weight)
	_frequency = lerpf(_frequency, _target_frequency, weight)
	_phase += TAU * _frequency * delta

	for i in _bones.size():
		var bone := _bones[i]
		var scale := lerpf(1.0, tip_gain, float(i) / maxf(_bones.size() - 1.0, 1.0))
		var angle := sin(_phase - i * phase_lag) * _amplitude * scale * gain
		var rotation := skeleton.get_bone_pose_rotation(bone)
		skeleton.set_bone_pose_rotation(bone, rotation * Quaternion(_axes[i], angle))
