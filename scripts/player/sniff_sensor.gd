class_name SniffSensor
extends Area3D
## におい検出とクンクン。近くのいいものを見つけ、近づいて長押しすると掘り出す。

signal progress_changed(value: float)
signal treasure_found(data: TreasureData)

## この距離(m)以内で長押しするとクンクンが進む
@export var sniff_range: float = 0.6
## false の間はクンクンできない(座っているときなど)
var enabled: bool = true
## においの届く半径にかける倍率(おすわりで広がる)
var smell_scale: float = 1.0

## いいものが足元よりこれ以上(m)高いところにあると、クンクンが届かない(切り株・岩の上はジャンプで乗る)
@export var max_height_gap: float = 0.15

## 発見までの長押し時間(秒)
@export var sniff_time: float = 1.0
## 離したときにゲージが戻る速さ(1秒あたり)
@export var release_decay: float = 2.0

## においが届いていて一番近いいいもの(なければ null)
var nearest: Treasure
## クンクン中(いいものが範囲内でボタン長押し)
var is_sniffing: bool = false
var progress: float = 0.0

var _candidates: Array[Treasure] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	nearest = _find_nearest()
	var in_range := nearest != null and _distance_to(nearest) <= sniff_range
	if in_range and nearest.global_position.y - global_position.y > max_height_gap:
		in_range = false  # 高いところ(切り株・岩の上)は、乗らないと届かない
	is_sniffing = enabled and in_range and Input.is_action_pressed("sniff")

	var previous := progress
	if is_sniffing:
		progress = minf(progress + delta / sniff_time, 1.0)
	else:
		progress = maxf(progress - release_decay * delta, 0.0)
	if progress != previous:
		progress_changed.emit(progress)

	if progress >= 1.0 and nearest:
		var data := nearest.data
		nearest.discover()
		_candidates.erase(nearest)
		nearest = null
		is_sniffing = false
		progress = 0.0
		progress_changed.emit(progress)
		treasure_found.emit(data)


func _find_nearest() -> Treasure:
	var best: Treasure = null
	var best_dist := INF
	for treasure in _candidates:
		if treasure.is_found:
			continue
		var dist := _distance_to(treasure)
		# 検出半径の中でも、そのいいもの自身のにおい半径に入ったものだけ
		if dist <= treasure.data.smell_radius * smell_scale and dist < best_dist:
			best_dist = dist
			best = treasure
	return best


func _distance_to(treasure: Treasure) -> float:
	var offset := treasure.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _on_area_entered(area: Area3D) -> void:
	if area is Treasure:
		_candidates.append(area)


func _on_area_exited(area: Area3D) -> void:
	if area is Treasure:
		_candidates.erase(area)
