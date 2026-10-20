class_name TreasureData
extends Resource
## 「いいもの」1種類ぶんの定義。

enum Shape { SPHERE, BOX, CYLINDER, CAPSULE }

@export var id: StringName
@export var display_name: String
## レア度(1〜3、★の数)
@export_range(1, 3) var rarity: int = 1
@export_multiline var description: String
## このいいもののにおいが届く半径(m)
@export var smell_radius: float = 3.0
## 抽選の重み(大きいほど出やすい)
@export var spawn_weight: float = 1.0
## 仮表示の形と色(scene が空のとき使う)
@export var shape: Shape = Shape.SPHERE
@export var color: Color = Color.WHITE
## 仮表示の大きさ(m)
@export var size: float = 0.1
## Meshy 製などの本番モデル。設定すると仮表示の代わりに使う
@export var scene: PackedScene


func stars() -> String:
	return "★".repeat(rarity)
