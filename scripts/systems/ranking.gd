class_name Ranking
extends RefCounted
## おさんぽのスコア計算と、ローカルのランキング(TOP10)。user://ranking.json に保存する。

const SAVE_PATH := "user://ranking.json"
const MAX_ENTRIES := 10
const NAME_LENGTH := 3

## いいもの1個の点数(レア度 ★1〜3)
const RARITY_POINTS := {1: 100, 2: 250, 3: 500}
## この秒数までにゴールすると、残り秒数 × TIME_POINTS_PER_SEC がもらえる
const TIME_LIMIT := 600.0
const TIME_POINTS_PER_SEC := 5
## いいものを全部あつめたときのボーナス
const COMPLETE_BONUS := 1000

## 順位の高い順。各要素は { name, score, seconds, found, total, date }
var entries: Array[Dictionary] = []


## スコアの内訳を返す: { treasure, time, complete, total }
static func calc_score(found: Array[TreasureData], elapsed: float, total_treasures: int) -> Dictionary:
	var treasure := 0
	for data in found:
		treasure += int(RARITY_POINTS.get(data.rarity, 0))
	var time_bonus := int(maxf(0.0, TIME_LIMIT - elapsed)) * TIME_POINTS_PER_SEC
	var complete := COMPLETE_BONUS if total_treasures > 0 and found.size() >= total_treasures else 0
	return {
		"treasure": treasure,
		"time": time_bonus,
		"complete": complete,
		"total": treasure + time_bonus + complete,
	}


static func load_or_new() -> Ranking:
	var ranking := Ranking.new()
	if not FileAccess.file_exists(SAVE_PATH):
		return ranking
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Array:
		push_warning("ランキングを読めなかったので、新しく始めます: " + SAVE_PATH)
		return ranking
	for item: Variant in parsed:
		if item is Dictionary and item.has_all(["name", "score", "seconds", "found", "total", "date"]):
			ranking.entries.append({
				"name": String(item["name"]).left(NAME_LENGTH),
				"score": int(item["score"]),
				"seconds": float(item["seconds"]),
				"found": int(item["found"]),
				"total": int(item["total"]),
				"date": String(item["date"]),
			})
	ranking._sort()
	ranking.entries.resize(mini(ranking.entries.size(), MAX_ENTRIES))
	return ranking


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ランキングの保存に失敗しました: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(entries, "\t"))


## このスコアが入る順位(0始まり)。TOP10に入らなければ -1。同点は先に登録した人が上
func rank_for(score: int, seconds: float) -> int:
	if score <= 0:
		return -1
	var index := 0
	for entry in entries:
		if _is_better(score, seconds, entry):
			break
		index += 1
	return index if index < MAX_ENTRIES else -1


## 登録して保存し、入った順位(0始まり)を返す。圏外なら -1
func add(player_name: String, score: int, seconds: float, found: int, total: int) -> int:
	var rank := rank_for(score, seconds)
	if rank < 0:
		return -1
	entries.insert(rank, {
		"name": player_name.left(NAME_LENGTH),
		"score": score,
		"seconds": seconds,
		"found": found,
		"total": total,
		"date": Time.get_date_string_from_system(),
	})
	entries.resize(mini(entries.size(), MAX_ENTRIES))
	save()
	return rank


## 新しい記録が既存の記録より上か(同点はタイムが速いほうが上。完全に同じなら既存が上)
static func _is_better(score: int, seconds: float, entry: Dictionary) -> bool:
	if score != entry["score"]:
		return score > entry["score"]
	return seconds < entry["seconds"]


func _sort() -> void:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _is_better(a["score"], a["seconds"], b))
