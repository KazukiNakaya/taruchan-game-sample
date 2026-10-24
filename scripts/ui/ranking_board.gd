class_name RankingBoard
extends VBoxContainer
## ランキング(TOP10)の表。リザルト・メニュー・名前入力のあとで共用する。


## highlight: 強調する順位(0始まり)。-1 なら強調なし
func show_entries(highlight: int = -1) -> void:
	for child in get_children():
		child.queue_free()
	add_theme_constant_override("separation", 4)
	add_child(_row("じゅんい", "なまえ", "スコア", "タイム", "あつめた", Color(0.2, 0.3, 0.15), 16))
	var entries := GameState.ranking.entries
	for i in Ranking.MAX_ENTRIES:
		if i < entries.size():
			var e := entries[i]
			var seconds := int(e["seconds"])
			var color := Color(0.85, 0.35, 0.1) if i == highlight else Color.WHITE
			add_child(_row("%d" % (i + 1), e["name"], "%d" % e["score"],
				"%d:%02d" % [seconds / 60, seconds % 60], "%d/%d" % [e["found"], e["total"]], color, 20))
		else:
			add_child(_row("%d" % (i + 1), "---", "-", "-", "-", Color(1, 1, 1, 0.4), 20))


func _row(rank: String, player_name: String, score: String, time: String, found: String, color: Color, font_size: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var widths := [80, 90, 110, 90, 90]
	var texts := [rank, player_name, score, time, found]
	for i in widths.size():
		var label := Label.new()
		label.text = texts[i]
		label.custom_minimum_size.x = widths[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if i != 2 else HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
		row.add_child(label)
	return row
