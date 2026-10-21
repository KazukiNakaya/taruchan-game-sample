class_name SaveData
extends Resource
## セーブデータ(図鑑の解放状況と日記)。user://save.tres に保存する。

const SAVE_PATH := "user://save.tres"

## 図鑑に登録済みのいいものの id
@export var discovered: PackedStringArray = PackedStringArray()
@export var diary: Array[DiaryEntry] = []


static func load_or_new() -> SaveData:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
		if loaded:
			return loaded
		push_warning("セーブデータを読めなかったので、新しく始めます: " + SAVE_PATH)
	return SaveData.new()


func save() -> void:
	var err := ResourceSaver.save(self, SAVE_PATH)
	if err != OK:
		push_error("セーブに失敗しました: %s" % error_string(err))


func is_discovered(id: StringName) -> bool:
	return discovered.has(String(id))
