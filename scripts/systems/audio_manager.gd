extends Node
## 効果音・BGM・環境音の再生と音量の一元管理(autoload: AudioManager)。
## 音は名前で読み込む。本番素材は、同じファイル名で audio/ 以下に置けば差し替わる。

const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENT: StringName = &"Ambient"
const BUS_UI: StringName = &"UI"

## バスごとの音量(dB)。ここを変えれば全体の音量バランスが変わる
const BUS_VOLUME_DB: Dictionary = {
	BUS_MUSIC: -16.0,
	BUS_SFX: -8.0,
	BUS_AMBIENT: -10.0,
	BUS_UI: -9.0,
}

## 効果音の名前 → ファイル(複数あればランダムに選ぶ。{n} は 1..count)
const SOUNDS: Dictionary = {
	&"sniff": ["res://audio/sfx/sniff_{n}.wav", 3],
	&"dig": ["res://audio/sfx/dig_{n}.wav", 2],
	&"discover": ["res://audio/sfx/discover.wav", 1],
	&"goal": ["res://audio/sfx/goal.wav", 1],
	&"jump": ["res://audio/sfx/jump.wav", 1],
	&"land": ["res://audio/sfx/land.wav", 1],
	&"ui_click": ["res://audio/sfx/ui_click.wav", 1],
	&"menu_open": ["res://audio/sfx/menu_open.wav", 1],
	&"menu_close": ["res://audio/sfx/menu_close.wav", 1],
	&"bird": ["res://audio/ambient/bird_{n}.wav", 4],
}
const BGM_PATH: String = "res://audio/bgm/forest_loop.wav"
const SFX_VOICES: int = 8

var _streams: Dictionary = {}  # 名前 -> AudioStream(複数ならランダマイザ)
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var _bird_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # メニュー中(ゲーム停止中)も鳴らす
	_setup_buses()
	_load_sounds()
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_MUSIC
	add_child(_bgm_player)
	_bird_timer = Timer.new()
	_bird_timer.one_shot = true
	_bird_timer.timeout.connect(_on_bird_timer)
	add_child(_bird_timer)
	# どのボタンにも、押したときのクリック音をつける
	get_tree().node_added.connect(_on_node_added)


## 効果音を鳴らす。bus を指定しなければ SFX バス
func play_sfx(sound: StringName, volume_db: float = 0.0, bus: StringName = BUS_SFX) -> void:
	var stream := _streams.get(sound) as AudioStream
	if stream == null:
		return
	var player := _free_player()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume_db
	player.play()


func play_ui(sound: StringName) -> void:
	play_sfx(sound, 0.0, BUS_UI)


func start_bgm() -> void:
	if _bgm_player.playing:
		return
	var stream := load(BGM_PATH) as AudioStreamWAV
	if stream == null:
		return
	stream = stream.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_bgm_player.stream = stream
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()


## 森の環境音(鳥の声が、プレイヤーの周りのどこかから、ときどき聞こえる)を始める
func start_ambient() -> void:
	_bird_timer.start(randf_range(2.0, 5.0))


func stop_ambient() -> void:
	_bird_timer.stop()


func _setup_buses() -> void:
	for bus_name in BUS_VOLUME_DB:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), BUS_VOLUME_DB[bus_name])


func _load_sounds() -> void:
	for sound in SOUNDS:
		var pattern: String = SOUNDS[sound][0]
		var count: int = SOUNDS[sound][1]
		if count == 1:
			var single := _try_load(pattern.replace("{n}", "1"))
			if single:
				_streams[sound] = single
			continue
		var randomizer := AudioStreamRandomizer.new()
		randomizer.random_pitch = 1.08
		var added := 0
		for n in range(1, count + 1):
			var stream := _try_load(pattern.replace("{n}", str(n)))
			if stream:
				randomizer.add_stream(added, stream)
				added += 1
		if added > 0:
			_streams[sound] = randomizer


func _try_load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("音のファイルがありません: " + path)
		return null
	return load(path) as AudioStream


func _free_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var click := play_ui.bind(&"ui_click")
		if not (node as BaseButton).pressed.is_connected(click):
			(node as BaseButton).pressed.connect(click)


func _on_bird_timer() -> void:
	var stream := _streams.get(&"bird") as AudioStream
	var player_node := get_tree().get_first_node_in_group(&"player") as Node3D
	if stream and player_node:
		var voice := AudioStreamPlayer3D.new()
		voice.bus = BUS_AMBIENT
		voice.stream = stream
		voice.unit_size = 6.0
		voice.max_distance = 40.0
		voice.finished.connect(voice.queue_free)
		add_child(voice)
		var angle := randf() * TAU
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * randf_range(6.0, 14.0)
		voice.global_position = player_node.global_position + offset + Vector3(0.0, randf_range(2.0, 6.0), 0.0)
		voice.play()
	_bird_timer.start(randf_range(4.0, 10.0))
