# MusicManager.gd - 全局背景音乐管理器
extends Node

# 音量整体压低：舒缓背景音乐，不抢游戏音效/操作反馈。
const DEFAULT_VOLUME_DB := -18.0
const BATTLE_VOLUME_DB  := -16.0
const FADE_SECONDS      := 1.20

# 请将拥有授权的音频文件放到 frontend/assets/music/ 下，并使用以下文件名。
# Godot 支持 ogg/mp3/wav；此处优先按 .ogg 引用，若你使用 mp3，请同步修改路径。
const MENU_MUSIC_PATH := "res://assets/music/menu_yungongxunyin_new.ogg"       # 《云宫迅音》新版 / 黑神话风格启动默认背景音乐
const STAGE_MUSIC_PATHS := [
	"res://assets/music/stage_soldier_ganwenlu.ogg",      # 小兵阶段：敢问路在何方（改版）
	"res://assets/music/stage_elite_chengwang.ogg",       # 精英阶段：称王称圣任纵横（开场主题曲）
	"res://assets/music/stage_boss_kanjian.ogg",          # 大妖阶段：陈鸿宇 - 看见（黑风山片尾曲）
]

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _idle_player: AudioStreamPlayer
var _current_track_path := ""
var _enabled := true

func _ready():
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	_player_a.name = "MusicPlayerA"
	_player_b.name = "MusicPlayerB"
	_player_a.bus = "Master"
	_player_b.bus = "Master"
	add_child(_player_a)
	add_child(_player_b)
	_active_player = _player_a
	_idle_player = _player_b
	play_menu_music()

func play_menu_music():
	play_track(MENU_MUSIC_PATH, DEFAULT_VOLUME_DB)

func play_current_battle_music():
	var blind := clampi(RoundManager.current_blind, 0, 2)
	play_stage_music(blind)

func play_stage_music(blind: int):
	var idx := clampi(blind, 0, STAGE_MUSIC_PATHS.size() - 1)
	play_track(STAGE_MUSIC_PATHS[idx], BATTLE_VOLUME_DB)

func stop_music(fade_seconds: float = FADE_SECONDS):
	_current_track_path = ""
	for player in [_player_a, _player_b]:
		if player and player.playing:
			var tw = create_tween()
			tw.tween_property(player, "volume_db", -80.0, fade_seconds)
			tw.tween_callback(func(): player.stop())

func set_music_enabled(enabled: bool):
	_enabled = enabled
	if not _enabled:
		stop_music(0.35)
	elif _current_track_path == "":
		play_menu_music()

func play_track(path: String, volume_db: float = DEFAULT_VOLUME_DB):
	if not _enabled:
		return
	if path == _current_track_path and _active_player and _active_player.playing:
		return
	if not ResourceLoader.exists(path):
		push_warning("MusicManager: 音频文件不存在，请放置授权音乐文件：%s" % path)
		return
	var stream = load(path)
	if stream == null:
		push_warning("MusicManager: 音频加载失败：%s" % path)
		return
	_current_track_path = path
	_crossfade_to(stream, volume_db)

func _crossfade_to(stream: AudioStream, target_volume_db: float):
	var next_player := _idle_player
	var prev_player := _active_player
	next_player.stream = stream
	_set_stream_loop(next_player.stream, true)
	next_player.volume_db = -80.0
	next_player.play()

	var tw = create_tween()
	tw.tween_property(next_player, "volume_db", target_volume_db, FADE_SECONDS)
	if prev_player and prev_player.playing:
		tw.parallel().tween_property(prev_player, "volume_db", -80.0, FADE_SECONDS)
		tw.tween_callback(func(): prev_player.stop())

	_active_player = next_player
	_idle_player = prev_player

func _set_stream_loop(stream: AudioStream, enabled: bool):
	if stream == null:
		return
	for prop in stream.get_property_list():
		if prop.get("name", "") == "loop":
			stream.set("loop", enabled)
			return