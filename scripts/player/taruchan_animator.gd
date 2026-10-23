class_name TaruchanAnimator
extends Node
## たるちゃんのアニメ切り替え(待機/歩き/小走り/ジャンプ)。
## 本番アニメ(idle / run)がモデルに無い間は、歩きアニメで代用する。名前が届けば自動で使う。

enum State { GROUND, JUMP_START, JUMP_AIR, JUMP_LAND, DIG }

const IDLE: StringName = &"idle"
const WALK: StringName = &"walk"
const RUN: StringName = &"run"
const JUMP_START: StringName = &"jump_start"
const JUMP_AIR: StringName = &"jump_air"
const JUMP_LAND: StringName = &"jump_land"
const SNIFF: StringName = &"sniff"
const DIG: StringName = &"dig"

## 歩きアニメが足滑りしない速度(m/s)
const WALK_ANIM_SPEED: float = 0.32
## 小走りアニメが足滑りしない速度(m/s)。本番の run が来たら実機で合わせる
const RUN_ANIM_SPEED: float = 0.9
## 仮の小走り(歩きの早回し)で、再生速度の上限
const MAX_WALK_SCALE: float = 3.0
## アニメ同士のなめらかな切り替えの長さ(秒)
const BLEND: float = 0.15
## 動いているとみなす速度(m/s)
const MOVE_THRESHOLD: float = 0.05
## ジャンプ直後、まだ接地判定が残っていても着地とみなさない時間(秒)
const TAKEOFF_GRACE: float = 0.12

var _player: AnimationPlayer
var _state: State = State.GROUND
var _timer: float = 0.0
var _grace: float = 0.0
var _current: StringName = &""


func setup(player: AnimationPlayer) -> void:
	_player = player


func is_jumping() -> bool:
	return _state != State.GROUND


## 掘る動作の最中(動けない)
func is_digging() -> bool:
	return _state == State.DIG


## 掘る動作を duration 秒だけ再生する(dig が無ければ sniff、それも無ければ待機)
func start_dig(duration: float) -> void:
	_state = State.DIG
	_timer = duration
	_play(_first_existing([DIG, SNIFF, IDLE]), 1.0)


func start_jump() -> void:
	_state = State.JUMP_START
	_grace = TAKEOFF_GRACE
	_timer = _length(JUMP_START)
	_play(JUMP_START, 1.0)


func update(delta: float, on_floor: bool, speed: float, running: bool, sniffing: bool = false) -> void:
	_grace = maxf(_grace - delta, 0.0)
	match _state:
		State.JUMP_START:
			_timer -= delta
			if on_floor and _grace <= 0.0:
				_land()
			elif _timer <= 0.0:
				_state = State.JUMP_AIR
				_play(JUMP_AIR, 1.0)
		State.JUMP_AIR:
			if on_floor and _grace <= 0.0:
				_land()
		State.JUMP_LAND:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.GROUND
		State.DIG:
			_timer -= delta
			if _timer <= 0.0:
				_state = State.GROUND
		State.GROUND:
			if not on_floor and _grace <= 0.0:
				_state = State.JUMP_AIR
				_play(JUMP_AIR, 1.0)
	if _state == State.GROUND:
		_update_ground(speed, running, sniffing)


func _land() -> void:
	if _player.has_animation(JUMP_LAND):
		_state = State.JUMP_LAND
		_timer = _length(JUMP_LAND)
		_play(JUMP_LAND, 1.0)
	else:
		_state = State.GROUND


func _update_ground(speed: float, running: bool, sniffing: bool) -> void:
	if sniffing and _player.has_animation(SNIFF):
		_play(SNIFF, 1.0)
	elif speed < MOVE_THRESHOLD:
		if _player.has_animation(IDLE):
			_play(IDLE, 1.0)
		else:
			_play_frozen_walk()
	elif running and _player.has_animation(RUN):
		_play(RUN, speed / RUN_ANIM_SPEED)
	else:
		_play(WALK, minf(speed / WALK_ANIM_SPEED, MAX_WALK_SCALE))


## 待機アニメが無い間: 歩きの最初のポーズで止める
func _play_frozen_walk() -> void:
	if _current != &"_frozen_walk":
		_current = &"_frozen_walk"
		_player.play(WALK, BLEND)
		_player.seek(0.0, true)
	_player.speed_scale = 0.0


func _play(anim: StringName, scale: float) -> void:
	if _current != anim:
		_current = anim
		_player.play(anim, BLEND)
	_player.speed_scale = scale


func _first_existing(names: Array[StringName]) -> StringName:
	for anim in names:
		if _player.has_animation(anim):
			return anim
	return WALK


func _length(anim: StringName) -> float:
	return _player.get_animation(anim).length if _player.has_animation(anim) else 0.0
