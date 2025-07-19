extends GutTest

# AudioManager单元测试
# 测试音频播放器对象池、音效播放、音乐播放和性能统计功能

# 预加载AudioManager脚本
const AudioManagerScript = preload("res://scripts/managers/audio_manager.gd")
var audio_manager: Node

func before_each():
	# 创建测试实例
	audio_manager = AudioManagerScript.new()
	audio_manager._ready()  # 手动调用初始化

func after_each():
	if audio_manager:
		audio_manager.queue_free()
	audio_manager = null

func test_audio_manager_initialization():
	# 测试AudioManager初始化
	assert_not_null(audio_manager, "AudioManager应该被正确创建")
	assert_eq(audio_manager._sfx_player_pool.size(), 0, "音效播放器池初始应该为空")
	assert_eq(audio_manager._music_player_pool.size(), 0, "音乐播放器池初始应该为空")
	assert_eq(audio_manager._active_sfx_players.size(), 0, "活跃音效播放器初始应该为空")
	assert_eq(audio_manager._active_music_players.size(), 0, "活跃音乐播放器初始应该为空")

func test_sfx_player_pool_management():
	# 测试音效播放器对象池管理
	var player = audio_manager._get_sfx_player_from_pool()
	assert_not_null(player, "应该能从池中获取音效播放器")
	assert_true(player is AudioStreamPlayer, "返回的应该是AudioStreamPlayer类型")
	
	# 测试回收
	audio_manager._recycle_sfx_player(player)
	assert_eq(audio_manager._sfx_player_pool.size(), 1, "回收后池中应该有1个播放器")

func test_music_player_pool_management():
	# 测试音乐播放器对象池管理
	var player = audio_manager._get_music_player_from_pool()
	assert_not_null(player, "应该能从池中获取音乐播放器")
	assert_true(player is AudioStreamPlayer, "返回的应该是AudioStreamPlayer类型")
	
	# 测试回收
	audio_manager._recycle_music_player(player)
	assert_eq(audio_manager._music_player_pool.size(), 1, "回收后池中应该有1个播放器")

func test_play_sfx_with_valid_sound():
	# 测试播放有效音效
	var player = audio_manager.play_sfx("jump")
	assert_not_null(player, "播放有效音效应该返回播放器")
	assert_true(player is AudioStreamPlayer, "返回的应该是AudioStreamPlayer类型")
	assert_not_null(player.stream, "播放器应该有音频流")
	
	# 验证活跃播放器记录
	assert_gt(audio_manager._active_sfx_players.size(), 0, "应该有活跃的音效播放器")

func test_play_sfx_with_invalid_sound():
	# 测试播放无效音效
	var player = audio_manager.play_sfx("nonexistent")
	assert_null(player, "播放无效音效应该返回null")

func test_play_music_with_valid_music():
	# 测试播放有效音乐
	var player = audio_manager.play_music("adventure")
	assert_not_null(player, "播放有效音乐应该返回播放器")
	assert_true(player is AudioStreamPlayer, "返回的应该是AudioStreamPlayer类型")
	assert_not_null(player.stream, "播放器应该有音频流")
	
	# 验证活跃播放器记录
	assert_gt(audio_manager._active_music_players.size(), 0, "应该有活跃的音乐播放器")

func test_play_music_with_invalid_music():
	# 测试播放无效音乐
	var player = audio_manager.play_music("nonexistent")
	assert_null(player, "播放无效音乐应该返回null")

func test_stop_all_sfx():
	# 测试停止所有音效
	var player1 = audio_manager.play_sfx("jump")
	var player2 = audio_manager.play_sfx("jump")
	
	assert_gt(audio_manager._active_sfx_players.size(), 0, "应该有活跃的音效播放器")
	
	audio_manager.stop_all_sfx()
	assert_eq(audio_manager._active_sfx_players.size(), 0, "停止后应该没有活跃的音效播放器")

func test_stop_all_music():
	# 测试停止所有音乐
	var player = audio_manager.play_music("adventure")
	
	assert_gt(audio_manager._active_music_players.size(), 0, "应该有活跃的音乐播放器")
	
	audio_manager.stop_all_music()
	assert_eq(audio_manager._active_music_players.size(), 0, "停止后应该没有活跃的音乐播放器")

func test_volume_control():
	# 测试音量控制
	var initial_sfx_volume = audio_manager.get_bus_volume(AudioManager.AudioBus.SFX)
	var initial_music_volume = audio_manager.get_bus_volume(AudioManager.AudioBus.MUSIC)
	
	# 设置新音量
	audio_manager.set_bus_volume(AudioManager.AudioBus.SFX, -20.0)
	audio_manager.set_bus_volume(AudioManager.AudioBus.MUSIC, -15.0)
	
	assert_eq(audio_manager.get_bus_volume(AudioManager.AudioBus.SFX), -20.0, "音效音量应该被正确设置")
	assert_eq(audio_manager.get_bus_volume(AudioManager.AudioBus.MUSIC), -15.0, "音乐音量应该被正确设置")

func test_performance_stats():
	# 测试性能统计
	var stats = audio_manager.get_performance_stats()
	
	assert_true(stats.has("active_sfx_players"), "应该有active_sfx_players统计")
	assert_true(stats.has("active_music_players"), "应该有active_music_players统计")
	assert_true(stats.has("sfx_pool_size"), "应该有sfx_pool_size统计")
	assert_true(stats.has("music_pool_size"), "应该有music_pool_size统计")
	assert_true(stats.has("total_sfx_played"), "应该有total_sfx_played统计")
	assert_true(stats.has("total_music_played"), "应该有total_music_played统计")

func test_max_players_limit():
	# 测试最大播放器数量限制
	var players = []
	
	# 尝试创建超过最大数量的播放器
	for i in range(audio_manager._max_sfx_players + 5):
		var player = audio_manager.play_sfx("jump")
		if player:
			players.append(player)
	
	assert_le(audio_manager._active_sfx_players.size(), audio_manager._max_sfx_players, "活跃播放器数量不应超过最大限制")

func test_signal_emissions():
	# 测试信号发射
	var sfx_started_fired = false
	var sfx_finished_fired = false
	
	audio_manager.sfx_started.connect(func(sound_name):
		sfx_started_fired = true
	)
	
	audio_manager.sfx_finished.connect(func(sound_name):
		sfx_finished_fired = true
	)
	
	# 播放音效
	var player = audio_manager.play_sfx("jump")
	assert_true(sfx_started_fired, "应该触发sfx_started信号")
	
	# 模拟播放完成
	if player:
		player.finished.emit()
		await get_tree().process_frame
		assert_true(sfx_finished_fired, "应该触发sfx_finished信号")

func test_cleanup_functionality():
	# 测试清理功能
	# 播放一些音效
	var player1 = audio_manager.play_sfx("jump")
	var player2 = audio_manager.play_sfx("jump")
	
	# 手动触发清理
	audio_manager._cleanup_inactive_players()
	
	# 验证清理不会影响正在播放的音频
	assert_gt(audio_manager._active_sfx_players.size(), 0, "正在播放的音频不应被清理")

func test_fade_in_music():
	# 测试音乐淡入
	var player = audio_manager.play_music_with_fade_in("adventure", 1.0)
	assert_not_null(player, "淡入播放应该返回播放器")
	
	# 验证初始音量为0
	assert_eq(player.volume_db, -80.0, "淡入开始时音量应该为最小值")

func test_is_music_playing():
	# 测试音乐播放状态检查
	assert_false(audio_manager.is_music_playing(), "初始状态应该没有音乐播放")
	
	var player = audio_manager.play_music("adventure")
	if player:
		assert_true(audio_manager.is_music_playing(), "播放音乐后应该返回true")