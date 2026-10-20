extends Node
## 今回のおさんぽの記録(autoload: GameState)。

signal treasure_added(data: TreasureData)

var found: Array[TreasureData] = []
var elapsed: float = 0.0
var distance: float = 0.0
var running: bool = false


func _process(delta: float) -> void:
	if running:
		elapsed += delta


func start_walk() -> void:
	found.clear()
	elapsed = 0.0
	distance = 0.0
	running = true


func finish_walk() -> void:
	running = false


func add_found(data: TreasureData) -> void:
	found.append(data)
	treasure_added.emit(data)


func add_distance(meters: float) -> void:
	if running:
		distance += meters
