class_name Treasure
extends Area3D
## 地面に埋まっている「いいもの」。クンクンで掘り出すまで見えない。

signal discovered(data: TreasureData)

@export var data: TreasureData

var is_found: bool = false

var _visual: Node3D


func _ready() -> void:
	add_to_group(&"treasure")
	_build_visual()
	_visual.visible = false


## 発見演出: 地面から出てきて、少し見せてから消える
func discover() -> void:
	if is_found:
		return
	is_found = true
	discovered.emit(data)
	_visual.position = Vector3(0.0, -data.size, 0.0)
	_visual.scale = Vector3.ONE * 0.3
	_visual.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "position:y", data.size * 0.6, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(1.2)
	tween.chain().tween_property(_visual, "scale", Vector3.ZERO, 0.4)
	tween.chain().tween_callback(queue_free)


func _build_visual() -> void:
	if data.scene:
		_visual = data.scene.instantiate() as Node3D
	else:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = _make_mesh()
		var material := StandardMaterial3D.new()
		material.albedo_color = data.color
		mesh_instance.material_override = material
		_visual = mesh_instance
	add_child(_visual)


func _make_mesh() -> Mesh:
	var s := data.size
	match data.shape:
		TreasureData.Shape.BOX:
			var box := BoxMesh.new()
			box.size = Vector3(s, s * 0.2, s)
			return box
		TreasureData.Shape.CYLINDER:
			var cyl := CylinderMesh.new()
			cyl.top_radius = s * 0.08
			cyl.bottom_radius = s * 0.08
			cyl.height = s
			cyl.rings = 1
			return cyl
		TreasureData.Shape.CAPSULE:
			var cap := CapsuleMesh.new()
			cap.radius = s * 0.35
			cap.height = s
			return cap
		_:
			var sph := SphereMesh.new()
			sph.radius = s * 0.5
			sph.height = s
			return sph
