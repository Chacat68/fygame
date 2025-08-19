extends Node

# 音频管理器
# 专门负责游戏中所有音频的播放、管理和优化
# 注意：此脚本作为AutoLoad单例使用，不应使用class_name

# 信号定义
signal audio_finished(audio_id: String)
signal music_changed(old_track: String, new_track: String)
signal volume_changed(bus_name: String, volume: float)

# 音频总线枚举
enum AudioBus {
	MASTER,
	MUSIC,
	SFX
}

# 音频播放器对象池
var _sfx_player_pool: Array[AudioStreamPlayer] = []
var _music_player_pool: Array[AudioStreamPlayer] = []
var _max_sfx_players: int = 15  # 最大音效播放器数量
var _max_music_players: int = 2   # 最大音乐播放器数量

# 活跃的音频播放器
var _active_sfx_players: Dictionary = {}  # audio_id -> AudioStreamPlayer
var _active_music_players: Dictionary = {} # track_name -> AudioStreamPlayer

# 当前播放状态
var _current_music_track: String = ""
var _music_volume: float = 0.8
var _sfx_volume: float = 1.0
var _master_volume: float = 1.0

# 音频淡入淡出
var _fade_tween: Tween
var _fade_duration: float = 1.0

# 性能统计
var _audio_stats: Dictionary = {
	"total_sfx_played": 0,
	"total_music_played": 0,
	"active_sfx_count": 0,
	"pool_sfx_count": 0,
	"pool_music_count": 0
}

# 音频配置
var _audio_config: Dictionary = {
	"max_concurrent_sfx": 8,  # 最大同时播放音效数
	"sfx_priority_threshold": 0.5,  # 音效优先级阈值
	"auto_cleanup_interval": 30.0,  # 自动清理间隔（秒）
	"fade_out_duration": 0.5  # 淡出持续时间
}

# 初始化
func _ready() -> void:
	add_to_group("audio_manager")
	_setup_audio_buses()
	_setup_fade_tween()
	_setup_cleanup_timer()
	print("音频管理器初始化完成")

# 设置音频总线
func _setup_audio_buses() -> void:
	# 设置初始音量
	set_bus_volume(AudioBus.MASTER, _master_volume)
	set_bus_volume(AudioBus.MUSIC, _music_volume)
	set_bus_volume(AudioBus.SFX, _sfx_volume)

# 设置淡入淡出动画
func _setup_fade_tween() -> void:
	# 在Godot 4中，Tween应该在需要时创建，而不是预先创建
	# _fade_tween将在需要时通过_get_fade_tween()获取
	pass

# 获取或创建淡入淡出Tween
func _get_fade_tween() -> Tween:
	if _fade_tween and _fade_tween.is_valid():
		return _fade_tween
	_fade_tween = create_tween()
	return _fade_tween

# 设置清理计时器
func _setup_cleanup_timer() -> void:
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = _audio_config["auto_cleanup_interval"]
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(_periodic_cleanup)
	add_child(cleanup_timer)

# 播放音效（优化版）
func play_sfx(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0, priority: float = 1.0) -> String:
	# 检查是否超过最大并发数
	if _active_sfx_players.size() >= _audio_config["max_concurrent_sfx"]:
		_cleanup_low_priority_sfx(priority)
	
	# 获取音频资源
	var sound_resource = ResourceManager.get_sound(sound_name)
	if not sound_resource:
		print("警告：音效资源不存在: ", sound_name)
		return ""
	
	# 生成唯一ID
	var audio_id = "%s_%d" % [sound_name, Time.get_unix_time_from_system()]
	
	# 获取音频播放器
	var audio_player = _get_sfx_player_from_pool()
	_configure_sfx_player(audio_player, sound_resource, volume_db, pitch_scale)
	
	# 添加到场景树
	add_child(audio_player)
	
	# 播放音效
	audio_player.play()
	
	# 记录活跃播放器
	_active_sfx_players[audio_id] = audio_player
	
	# 设置播放完成回调
	audio_player.finished.connect(_on_sfx_finished.bind(audio_id), CONNECT_ONE_SHOT)
	
	# 更新统计
	_audio_stats["total_sfx_played"] += 1
	_audio_stats["active_sfx_count"] = _active_sfx_players.size()
	
	return audio_id

# 播放背景音乐
func play_music(track_name: String, fade_in: bool = true, loop: bool = true) -> bool:
	# 获取音乐资源
	var music_resource = ResourceManager.get_music(track_name)
	if not music_resource:
		print("警告：音乐资源不存在: ", track_name)
		return false
	
	# 如果已经在播放相同音乐，跳过
	if _current_music_track == track_name and _active_music_players.has(track_name):
		print("音乐已在播放: ", track_name)
		return true
	
	# 停止当前音乐
	if _current_music_track != "":
		stop_music(true)
	
	# 获取音乐播放器
	var music_player = _get_music_player_from_pool()
	_configure_music_player(music_player, music_resource, loop)
	
	# 添加到场景树
	add_child(music_player)
	
	# 设置音频总线
	music_player.bus = "Music"
	
	# 播放音乐
	if fade_in:
		music_player.volume_db = -80.0  # 从静音开始
		music_player.play()
		_fade_in_music(music_player)
	else:
		music_player.play()
	
	# 记录状态
	var old_track = _current_music_track
	_current_music_track = track_name
	_active_music_players[track_name] = music_player
	
	# 发送信号
	music_changed.emit(old_track, track_name)
	
	# 更新统计
	_audio_stats["total_music_played"] += 1
	
	print("开始播放音乐: ", track_name)
	return true

# 停止音效
func stop_sfx(audio_id: String, fade_out: bool = false) -> void:
	if not _active_sfx_players.has(audio_id):
		return
	
	var audio_player = _active_sfx_players[audio_id]
	if fade_out:
		_fade_out_audio(audio_player, func(): _recycle_sfx_player(audio_id))
	else:
		_recycle_sfx_player(audio_id)

# 停止背景音乐
func stop_music(fade_out: bool = true) -> void:
	if _current_music_track == "":
		return
	
	var music_player = _active_music_players.get(_current_music_track)
	if music_player:
		if fade_out:
			_fade_out_audio(music_player, func(): _recycle_music_player(_current_music_track))
		else:
			_recycle_music_player(_current_music_track)

# 停止所有音效
func stop_all_sfx(fade_out: bool = false) -> void:
	var audio_ids = _active_sfx_players.keys()
	for audio_id in audio_ids:
		stop_sfx(audio_id, fade_out)

# 设置音频总线音量
func set_bus_volume(bus: AudioBus, volume: float) -> void:
	var bus_name = _get_bus_name(bus)
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		var volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
		AudioServer.set_bus_volume_db(bus_index, volume_db)
		volume_changed.emit(bus_name, volume)
		
		# 更新内部状态
		match bus:
			AudioBus.MASTER:
				_master_volume = volume
			AudioBus.MUSIC:
				_music_volume = volume
			AudioBus.SFX:
				_sfx_volume = volume

# 获取音频总线音量
func get_bus_volume(bus: AudioBus) -> float:
	match bus:
		AudioBus.MASTER:
			return _master_volume
		AudioBus.MUSIC:
			return _music_volume
		AudioBus.SFX:
			return _sfx_volume
		_:
			return 0.0

# 从对象池获取音效播放器
func _get_sfx_player_from_pool() -> AudioStreamPlayer:
	if _sfx_player_pool.size() > 0:
		return _sfx_player_pool.pop_back()
	else:
		return AudioStreamPlayer.new()

# 从对象池获取音乐播放器
func _get_music_player_from_pool() -> AudioStreamPlayer:
	if _music_player_pool.size() > 0:
		return _music_player_pool.pop_back()
	else:
		return AudioStreamPlayer.new()

# 配置音效播放器
func _configure_sfx_player(player: AudioStreamPlayer, stream: AudioStream, volume_db: float, pitch_scale: float) -> void:
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = "SFX"

# 配置音乐播放器
func _configure_music_player(player: AudioStreamPlayer, stream: AudioStream, loop: bool) -> void:
	player.stream = stream
	player.volume_db = 0.0
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop

# 音效播放完成回调
func _on_sfx_finished(audio_id: String) -> void:
	audio_finished.emit(audio_id)
	_recycle_sfx_player(audio_id)

# 回收音效播放器
func _recycle_sfx_player(audio_id: String) -> void:
	if not _active_sfx_players.has(audio_id):
		return
	
	var audio_player = _active_sfx_players[audio_id]
	_active_sfx_players.erase(audio_id)
	
	# 重置播放器状态
	_reset_audio_player(audio_player)
	
	# 回收到对象池
	if _sfx_player_pool.size() < _max_sfx_players:
		_sfx_player_pool.append(audio_player)
	else:
		audio_player.queue_free()
	
	# 更新统计
	_audio_stats["active_sfx_count"] = _active_sfx_players.size()
	_audio_stats["pool_sfx_count"] = _sfx_player_pool.size()

# 回收音乐播放器
func _recycle_music_player(track_name: String) -> void:
	if not _active_music_players.has(track_name):
		return
	
	var music_player = _active_music_players[track_name]
	_active_music_players.erase(track_name)
	
	if _current_music_track == track_name:
		_current_music_track = ""
	
	# 重置播放器状态
	_reset_audio_player(music_player)
	
	# 回收到对象池
	if _music_player_pool.size() < _max_music_players:
		_music_player_pool.append(music_player)
	else:
		music_player.queue_free()
	
	# 更新统计
	_audio_stats["pool_music_count"] = _music_player_pool.size()

# 重置音频播放器状态
func _reset_audio_player(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null
	player.volume_db = 0.0
	player.pitch_scale = 1.0
	player.bus = "Master"
	
	# 从父节点移除
	if player.get_parent():
		player.get_parent().remove_child(player)

# 淡入音乐
func _fade_in_music(music_player: AudioStreamPlayer) -> void:
	var tween = _get_fade_tween()
	tween.tween_property(music_player, "volume_db", 0.0, _fade_duration)

# 淡出音频
func _fade_out_audio(audio_player: AudioStreamPlayer, callback: Callable) -> void:
	var tween = _get_fade_tween()
	tween.tween_property(audio_player, "volume_db", -80.0, _audio_config["fade_out_duration"])
	tween.tween_callback(callback)

# 清理低优先级音效
func _cleanup_low_priority_sfx(_new_priority: float) -> void:
	# 简单实现：移除最旧的音效
	# TODO: 未来可以使用_new_priority参数来实现更智能的清理策略
	if _active_sfx_players.size() > 0:
		var oldest_id = _active_sfx_players.keys()[0]
		stop_sfx(oldest_id, false)

# 定期清理
func _periodic_cleanup() -> void:
	# 清理无效的播放器引用
	var invalid_sfx_ids = []
	for audio_id in _active_sfx_players:
		var player = _active_sfx_players[audio_id]
		if not is_instance_valid(player):
			invalid_sfx_ids.append(audio_id)
	
	for audio_id in invalid_sfx_ids:
		_active_sfx_players.erase(audio_id)
	
	# 清理对象池中的无效对象
	_sfx_player_pool = _sfx_player_pool.filter(func(player): return is_instance_valid(player))
	_music_player_pool = _music_player_pool.filter(func(player): return is_instance_valid(player))
	
	# 更新统计
	_update_audio_stats()

# 更新音频统计
func _update_audio_stats() -> void:
	_audio_stats["active_sfx_count"] = _active_sfx_players.size()
	_audio_stats["pool_sfx_count"] = _sfx_player_pool.size()
	_audio_stats["pool_music_count"] = _music_player_pool.size()

# 获取音频总线名称
func _get_bus_name(bus: AudioBus) -> String:
	match bus:
		AudioBus.MASTER:
			return "Master"
		AudioBus.MUSIC:
			return "Music"
		AudioBus.SFX:
			return "SFX"
		_:
			return "Master"

# 获取当前播放的音乐
func get_current_music() -> String:
	return _current_music_track

# 检查音乐是否正在播放
func is_music_playing() -> bool:
	return _current_music_track != "" and _active_music_players.has(_current_music_track)

# 获取活跃音效数量
func get_active_sfx_count() -> int:
	return _active_sfx_players.size()

# 获取音频统计
func get_audio_stats() -> Dictionary:
	return _audio_stats.duplicate()

# 清理所有音频
func cleanup_all_audio() -> void:
	stop_all_sfx(false)
	stop_music(false)
	
	# 清理对象池
	for player in _sfx_player_pool:
		if is_instance_valid(player):
			player.queue_free()
	_sfx_player_pool.clear()
	
	for player in _music_player_pool:
		if is_instance_valid(player):
			player.queue_free()
	_music_player_pool.clear()
	
	print("音频管理器清理完成")
