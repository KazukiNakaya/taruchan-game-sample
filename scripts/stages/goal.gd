class_name Goal
extends Area3D
## ゴール(ベンチ)。ベンチの前でおすわりをするとおさんぽ終了。

signal reached

var _done: bool = false


func _physics_process(_delta: float) -> void:
	if _done:
		return
	for body in get_overlapping_bodies():
		if body is Taruchan and (body as Taruchan).is_seated():
			_done = true
			reached.emit()
			return
