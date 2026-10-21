class_name DiaryEntry
extends Resource
## おさんぽ日記の1ページ(1回のおさんぽ)。

@export var date_text: String
@export var duration: float
@export var distance: float
## 見つけたものの id(見つけた順、重複あり)
@export var found_ids: PackedStringArray = PackedStringArray()
## このおさんぽで初めて見つけたものの id
@export var new_ids: PackedStringArray = PackedStringArray()
