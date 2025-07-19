extends Node

# 音频管理器使用示例
# 展示如何在游戏中使用新的AudioManager系统

# 在游戏开始时播放背景音乐
func _ready() -> void:
	# 等待一帧确保AudioManager已初始化
	await get_tree().process_frame
	
	# 播放背景音乐（带淡入效果）
	AudioManager.play_music("adventure", true, true)
	
	# 设置音量
	AudioManager.set_bus_volume(AudioManager.AudioBus.MUSIC, 0.7)
	AudioManager.set_bus_volume(AudioManager.AudioBus.SFX, 0.8)
	
	# 连接音频事件信号
	AudioManager.music_changed.connect(_on_music_changed)
	AudioManager.volume_changed.connect(_on_volume_changed)
	
	print("音频管理器示例初始化完成")

# 播放音效示例
func play_example_sounds() -> void:
	# 播放跳跃音效
	var jump_id = AudioManager.play_sfx("jump")
	print("播放跳跃音效，ID: ", jump_id)
	
	# 播放带音量和音调的音效
	var coin_id = AudioManager.play_sfx("coin", -5.0, 1.2)  # 音量-5dB，音调1.2倍
	print("播放金币音效，ID: ", coin_id)
	
	# 播放高优先级音效
	var explosion_id = AudioManager.play_sfx("explosion", 0.0, 1.0, 2.0)  # 高优先级
	print("播放爆炸音效，ID: ", explosion_id)

# 音乐控制示例
func music_control_example() -> void:
	# 检查当前是否有音乐在播放
	if AudioManager.is_music_playing():
		print("当前播放音乐: ", AudioManager.get_current_music())
	
	# 切换到另一首音乐（如果有的话）
	# AudioManager.play_music("battle", true, true)
	
	# 停止当前音乐（带淡出效果）
	# AudioManager.stop_music(true)
	
	# 暂停所有音效
	# AudioManager.stop_all_sfx(true)

# 音量控制示例
func volume_control_example() -> void:
	# 获取当前音量
	var master_volume = AudioManager.get_bus_volume(AudioManager.AudioBus.MASTER)
	var music_volume = AudioManager.get_bus_volume(AudioManager.AudioBus.MUSIC)
	var sfx_volume = AudioManager.get_bus_volume(AudioManager.AudioBus.SFX)
	
	print("当前音量 - 主音量: %.2f, 音乐: %.2f, 音效: %.2f" % [master_volume, music_volume, sfx_volume])
	
	# 调整音量
	AudioManager.set_bus_volume(AudioManager.AudioBus.MASTER, 0.8)
	AudioManager.set_bus_volume(AudioManager.AudioBus.MUSIC, 0.6)
	AudioManager.set_bus_volume(AudioManager.AudioBus.SFX, 0.9)

# 性能统计示例
func show_audio_stats() -> void:
	var stats = AudioManager.get_audio_stats()
	print("音频统计:")
	print("  总播放音效数: ", stats["total_sfx_played"])
	print("  总播放音乐数: ", stats["total_music_played"])
	print("  活跃音效数: ", stats["active_sfx_count"])
	print("  音效池大小: ", stats["pool_sfx_count"])
	print("  音乐池大小: ", stats["pool_music_count"])
	
	# 获取活跃音效数量
	var active_count = AudioManager.get_active_sfx_count()
	print("  当前活跃音效数: ", active_count)

# 信号回调示例
func _on_music_changed(old_track: String, new_track: String) -> void:
	print("音乐切换: %s -> %s" % [old_track, new_track])

func _on_volume_changed(bus_name: String, volume: float) -> void:
	print("音量变化: %s = %.2f" % [bus_name, volume])

# 输入处理示例（用于测试）
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		play_example_sounds()
	elif event.is_action_pressed("dash"):
		music_control_example()
	elif event.is_action_pressed("slide"):
		volume_control_example()
		show_audio_stats()

# 清理示例
func _exit_tree() -> void:
	# 在节点销毁时清理所有音频
	AudioManager.cleanup_all_audio()
	print("音频管理器示例清理完成")

# 高级用法示例
func advanced_audio_examples() -> void:
	# 播放多个音效并管理它们
	var audio_ids = []
	for i in range(3):
		var id = AudioManager.play_sfx("coin", -10.0 + i * 2.0)  # 不同音量
		audio_ids.append(id)
	
	# 等待一段时间后停止特定音效
	await get_tree().create_timer(2.0).timeout
	for id in audio_ids:
		AudioManager.stop_sfx(id, true)  # 带淡出效果停止
	
	# 音乐淡入淡出切换示例
	if AudioManager.is_music_playing():
		AudioManager.stop_music(true)  # 淡出当前音乐
		await get_tree().create_timer(1.0).timeout  # 等待淡出完成
		AudioManager.play_music("adventure", true)  # 淡入新音乐