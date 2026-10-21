class_name TreasureCatalog
extends Resource
## 「いいもの」の全種類リスト。配置の抽選と図鑑の両方がこれを使う。

@export var treasures: Array[TreasureData] = []


func find(id: StringName) -> TreasureData:
	for data in treasures:
		if data.id == id:
			return data
	return null
