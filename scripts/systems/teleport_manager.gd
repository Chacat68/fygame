extends Node
# 传送管理器
# 负责处理游戏中的所有传送功能

class_name TeleportManager

const TAG = "TeleportManager"

# 传送相关信号
signal teleport_started(player, destination)
signal teleport_completed(player, destination)
signal teleport_failed(reason)
signal teleport_cooldown_finished()

# 传送配置
var config: TeleportConfig
var is_teleporting: bool = false
var last_teleport_time_msec: int = 0

# 传送特效节点
var tween: Tween
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect

# 初始化传送管理器
func _ready():
	# 将自己添加到传送管理器组，方便其他脚本查找
	add_to_group("teleport_manager")
	
	# 创建默认配置
	if not config:
		config = TeleportConfig.new()
		config.apply_preset(TeleportConfig.TeleportPreset.SMOOTH)
	
	# 在 Godot 4 中，Tween 是资源类型，不需要添加到场景树
	# 注意：每次使用时需要重新创建 Tween
	# tween 变量将在需要时通过 create_tween() 创建

# 设置传送配置
func set_config(new_config: TeleportConfig):
	config = new_config
	if not config.validate_config():
		Logger.warn(TAG, "配置验证失败，使用默认配置")
		config.reset_to_default()

# 检查是否可以传送（冷却时间检查）
func can_teleport() -> bool:
	if is_teleporting:
		return false
	
	var elapsed_ms = Time.get_ticks_msec() - last_teleport_time_msec
	return elapsed_ms >= int(config.cooldown_time * 1000)

# 传送到指定的Portal
func teleport_to_portal(player_node: Node2D = null) -> bool:
	# 检查是否可以传送
	if not can_teleport():
		teleport_failed.emit("传送冷却中，请稍后再试")
		return false
	
	if not player_node:
		player_node = _get_player()
	
	if not player_node:
		teleport_failed.emit("未找到玩家节点")
		return false
	
	# 查找Portal节点
	var portal = _find_portal()
	if not portal:
		teleport_failed.emit("未找到传送门节点")
		return false
	
	# 检查传送距离
	var distance = player_node.global_position.distance_to(portal.global_position)
	if distance > config.max_teleport_distance:
		teleport_failed.emit("传送距离过远")
		return false
	
	# 计算传送位置
	var destination = _calculate_teleport_position(portal)
	
	# 检查传送位置是否安全
	if not _is_position_safe(destination):
		# 尝试寻找附近的安全位置
		destination = _find_safe_position_near(destination)
	
	# 执行传送
	return _execute_teleport(player_node, destination)

# 传送到指定坐标
func teleport_to_position(player_node: Node2D, position: Vector2) -> bool:
	if not player_node:
		teleport_failed.emit("玩家节点无效")
		return false
	
	return _execute_teleport(player_node, position)

# 获取玩家节点
func _get_player() -> Node2D:
	# 检查场景树是否有效
	var tree = get_tree()
	if not tree:
		Logger.error(TAG, "场景树无效，无法获取玩家节点")
		return null
	
	var player = tree.get_first_node_in_group("player")
	if not player:
		Logger.warn(TAG, "未找到玩家节点")
	return player

# 查找Portal节点
func _find_portal() -> Node2D:
	# 检查场景树是否有效
	var tree = get_tree()
	if not tree:
		Logger.error(TAG, "场景树无效，无法查找Portal节点")
		return null
	
	# 首先尝试通过组查找
	var portal = tree.get_first_node_in_group("portal")
	if portal:
		return portal
	
	# 然后尝试通过节点名称查找
	if tree.current_scene:
		portal = tree.current_scene.get_node_or_null("Portal")
		if portal:
			return portal

		# 最后尝试递归查找所有Portal类型的节点
		portal = _find_node_by_type(tree.current_scene, "Portal")
		return portal
	
	return null

# 递归查找指定类型的节点
func _find_node_by_type(node: Node, type_name: String) -> Node:
	if node.name == type_name or node.get_script() and node.get_script().get_global_name() == type_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_type(child, type_name)
		if result:
			return result
	
	return null

# 计算传送位置
func _calculate_teleport_position(portal: Node2D) -> Vector2:
	return portal.global_position + config.portal_offset

# 检查位置是否安全（避免传送到墙体或危险区域）
func _is_position_safe(_position: Vector2) -> bool:
	# 这里可以添加更复杂的安全检查逻辑
	# 比如检查是否有碰撞体、是否在killzone等
	return true

# 在指定位置附近寻找安全位置
func _find_safe_position_near(original_position: Vector2) -> Vector2:
	# 简单实现：如果原位置不安全，尝试几个偏移位置
	var offsets = [
		Vector2(0, 0),
		Vector2(-config.safety_distance, 0),
		Vector2(config.safety_distance, 0),
		Vector2(0, -config.safety_distance),
		Vector2(0, config.safety_distance)
	]
	
	for offset in offsets:
		var test_position = original_position + offset
		if _is_position_safe(test_position):
			return test_position
	
	return original_position # 如果都不安全，返回原位置

# 执行传送
func _execute_teleport(player: Node2D, destination: Vector2) -> bool:
	is_teleporting = true
	teleport_started.emit(player, destination)
	
	# 记录传送时间
	last_teleport_time_msec = Time.get_ticks_msec()
	
	# 播放传送特效（如果启用）
	if config.enable_teleport_effects:
		_play_teleport_effect(player.global_position, destination)
	
	# 根据配置执行不同类型的传送
	if config.teleport_duration <= 0.0:
		# 瞬间传送
		_instant_teleport(player, destination)
	else:
		# 动画传送
		_animated_teleport(player, destination)
	
	return true

# 瞬间传送
func _instant_teleport(player: Node2D, destination: Vector2):
	player.global_position = destination
	_complete_teleport(player, destination)

# 动画传送
func _animated_teleport(player: Node2D, destination: Vector2):
	# 创建新的 Tween 实例
	tween = create_tween()
	
	# 淡出效果
	if config.fade_out_duration > 0:
		tween.tween_property(player, "modulate:a", 0.0, config.fade_out_duration)
		await tween.finished
	
	# 执行传送
	player.global_position = destination
	
	# 淡入效果
	if config.fade_in_duration > 0:
		# 为淡入效果创建新的 Tween
		tween = create_tween()
		tween.tween_property(player, "modulate:a", 1.0, config.fade_in_duration)
		await tween.finished
	
	_complete_teleport(player, destination)

# 完成传送
func _complete_teleport(player: Node2D, destination: Vector2):
	is_teleporting = false
	
	# 输出调试信息
	if config.log_teleport_events:
		Logger.info(TAG, "玩家已传送到：%s" % str(destination))
	
	teleport_completed.emit(player, destination)
	
	# 启动冷却计时器
	if config.cooldown_time > 0:
		# 检查场景树是否有效
		var tree = get_tree()
		if tree:
			await tree.create_timer(config.cooldown_time).timeout
			teleport_cooldown_finished.emit()
		else:
			Logger.warn(TAG, "场景树无效，跳过冷却时间")
			teleport_cooldown_finished.emit()

# 播放传送特效
func _play_teleport_effect(from_position: Vector2, to_position: Vector2):
	# 这里可以添加粒子效果、音效等
	# 目前只是简单的调试输出
	if config.log_teleport_events:
		Logger.debug(TAG, "播放传送特效：从 %s 到 %s" % [str(from_position), str(to_position)])

	# 屏幕闪烁
	if config.screen_flash_enabled:
		_play_screen_flash()

	# 轻量级玩家淡入淡出已经由主流程处理，这里避免重复处理
	# 可在此扩展粒子、音效等效果

# 屏幕闪烁效果
func _play_screen_flash() -> void:
	_ensure_flash_overlay()

	if not _flash_rect:
		return

	var viewport_rect = get_viewport().get_visible_rect()
	_flash_rect.size = viewport_rect.size
	_flash_rect.position = Vector2.ZERO
	_flash_rect.visible = true
	_flash_rect.color = Color(1, 1, 1, 0.0)

	var flash_tween = create_tween()
	flash_tween.set_trans(Tween.TRANS_SINE)
	flash_tween.set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(_flash_rect, "color:a", 0.6, 0.05)
	flash_tween.set_ease(Tween.EASE_IN)
	flash_tween.tween_property(_flash_rect, "color:a", 0.0, 0.2)
	flash_tween.tween_callback(func():
		if _flash_rect:
			_flash_rect.visible = false
	)

func _ensure_flash_overlay() -> void:
	if _flash_layer and is_instance_valid(_flash_layer):
		return

	var tree = get_tree()
	if not tree:
		return

	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 100
	_flash_layer.name = "TeleportFlashLayer"

	_flash_rect = ColorRect.new()
	_flash_rect.name = "TeleportFlashRect"
	_flash_rect.anchor_left = 0.0
	_flash_rect.anchor_top = 0.0
	_flash_rect.anchor_right = 1.0
	_flash_rect.anchor_bottom = 1.0
	_flash_rect.visible = false
	_flash_rect.color = Color(1, 1, 1, 0.0)

	_flash_layer.add_child(_flash_rect)
	tree.root.add_child(_flash_layer)

# 获取当前配置
func get_config() -> TeleportConfig:
	return config

# 重置为默认配置
func reset_to_default():
	config = TeleportConfig.new()
	config.apply_preset(TeleportConfig.TeleportPreset.INSTANT)

# 传送到指定场景
func teleport_to_scene(scene_path: String, spawn_position: Vector2 = Vector2.ZERO) -> bool:
	# 防止重复传送
	if is_teleporting:
		return false
	
	# 检查场景路径是否有效
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		teleport_failed.emit("场景路径无效或场景不存在：" + scene_path)
		return false
	
	# 获取玩家节点
	var player = _get_player()
	if not player:
		teleport_failed.emit("未找到玩家节点")
		return false
	
	# 开始传送过程
	is_teleporting = true
	teleport_started.emit(player, spawn_position)
	
	# 播放传送特效
	_play_teleport_effect(player.global_position, spawn_position)
	
	# 如果配置了淡出效果，先执行淡出
	if config.enable_teleport_effects and config.fade_out_duration > 0:
		tween = create_tween()
		tween.tween_property(player, "modulate:a", 0.0, config.fade_out_duration)
		await tween.finished
	
	# 使用 call_deferred 延迟切换场景，避免在物理回调中直接操作
	call_deferred("_change_scene_deferred", scene_path, spawn_position)
	return true

# 延迟执行的场景切换函数
func _change_scene_deferred(scene_path: String, spawn_position: Vector2):
	# 检查节点是否仍然有效
	if not is_inside_tree():
		Logger.warn(TAG, "不在场景树中，无法执行场景切换")
		is_teleporting = false
		return
	
	# 检查树是否仍然有效
	var tree = get_tree()
	if not tree:
		Logger.error(TAG, "场景树无效，无法执行场景切换")
		is_teleporting = false
		return

	# 切换场景
	var result = tree.change_scene_to_file(scene_path)
	if result != OK:
		Logger.error(TAG, "场景切换失败：" + scene_path)
		is_teleporting = false
		return

	# 等待场景加载完成
	# 注意：场景切换后，当前节点可能已被释放，所以不能再访问 get_tree()
	# 使用 Engine.get_main_loop() 来获取场景树
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var scene_tree = main_loop as SceneTree
		await scene_tree.process_frame
	else:
		Logger.warn(TAG, "无法获取场景树，跳过后续处理")
		is_teleporting = false
		return
	
	# 在新场景中设置玩家位置
	# 使用场景树来查找新玩家，而不是通过已释放的节点
	var current_scene_tree = Engine.get_main_loop() as SceneTree
	var new_player = null
	if current_scene_tree:
		new_player = current_scene_tree.get_first_node_in_group("player")
	
	if new_player and spawn_position != Vector2.ZERO:
		new_player.global_position = spawn_position
	
	# 如果配置了淡入效果，执行淡入
	if config and config.enable_teleport_effects and config.fade_in_duration > 0 and new_player:
		new_player.modulate.a = 0.0
		# 创建新的Tween，因为原来的可能已被释放
		var fade_tween = new_player.create_tween()
		fade_tween.tween_property(new_player, "modulate:a", 1.0, config.fade_in_duration)
		await fade_tween.finished
	
	# 完成传送
	is_teleporting = false
	teleport_completed.emit(new_player, spawn_position)
	
	# 进入新关卡时自动存档
	if SaveManager:
		# 更新当前关卡信息
		var current_save = SaveManager.get_current_save()
		if current_save:
			current_save.current_level = scene_path
		SaveManager.trigger_auto_save()
		Logger.info(TAG, "进入新关卡，已自动存档")
	
	# 输出调试信息
	if config.log_teleport_events:
		Logger.info(TAG, "场景传送完成：%s 位置：%s" % [scene_path, str(spawn_position)])
