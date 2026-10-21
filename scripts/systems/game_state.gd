extends Node
## 今回のおさんぽの記録とセーブデータ(autoload: GameState)。

signal treasure_added(data: TreasureData)

const CATALOG: TreasureCatalog = preload("res://data/treasure_catalog.tres")

var found: Array[TreasureData] = []
var elapsed: float = 0.0
var distance: float = 0.0
var running: bool = false
var save_data: SaveData
## 直近のおさんぽで初めて見つけたものの id
var last_new_ids: PackedStringArray = PackedStringArray()


func _ready() -> void:
	save_data = SaveData.load_or_new()


func _process(delta: float) -> void:
	if running:
		elapsed += delta


func start_walk() -> void:
	found.clear()
	last_new_ids = PackedStringArray()
	elapsed = 0.0
	distance = 0.0
	running = true


## おさんぽ終了: 日記に1ページ追加し、図鑑を更新してセーブする
func finish_walk() -> void:
	running = false
	var entry := DiaryEntry.new()
	entry.date_text = Time.get_datetime_string_from_system(false, true)
	entry.duration = elapsed
	entry.distance = distance
	for data in found:
		entry.found_ids.append(String(data.id))
		if not save_data.is_discovered(data.id) and not last_new_ids.has(String(data.id)):
			last_new_ids.append(String(data.id))
	entry.new_ids = last_new_ids
	for id in last_new_ids:
		save_data.discovered.append(id)
	save_data.diary.append(entry)
	save_data.save()


func add_found(data: TreasureData) -> void:
	found.append(data)
	treasure_added.emit(data)


func add_distance(meters: float) -> void:
	if running:
		distance += meters
