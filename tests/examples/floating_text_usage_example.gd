# 飘字系统使用示例
# 展示如何在游戏中使用新的排列飘字效果

extends Node2D

# 示例：在玩家获得经验值时显示飘字
func show_experience_gain(player_position: Vector2, exp_amount: int):
	# 获取游戏根节点
	var game_root = get_tree().get_root().get_node("Game")
	if not game_root:
		game_root = get_tree().get_root()
	
	# 使用飘字管理器创建排列效果
	var text_manager = FloatingTextManager.get_instance()
	text_manager.create_arranged_floating_text(
		player_position + Vector2(0, -40),
		"经验+" + str(exp_amount),
		game_root
	)

# 示例：显示多个不同类型的奖励
func show_multiple_rewards(base_position: Vector2, rewards: Array):
	var game_root = get_tree().get_root().get_node("Game")
	if not game_root:
		game_root = get_tree().get_root()
	
	var text_manager = FloatingTextManager.get_instance()
	
	# 为每个奖励创建飘字
	for reward in rewards:
		text_manager.create_arranged_floating_text(
			base_position,
			reward,
			game_root
		)

# 示例：在特定事件中使用
func _on_player_level_up(player_position: Vector2, new_level: int):
	# 显示升级信息
	show_experience_gain(player_position, 0)  # 可以传入0或实际经验值
	
	# 显示多个奖励
	var rewards = [
		"升级!",
		"等级+1",
		"生命+10",
		"攻击+5"
	]
	show_multiple_rewards(player_position + Vector2(0, -60), rewards)

# 示例：自定义飘字管理器参数
func customize_floating_text_settings():
	var text_manager = FloatingTextManager.get_instance()
	
	# 调整排列参数
	text_manager.horizontal_spacing = 50.0      # 增加水平间距
	text_manager.stagger_delay_interval = 0.15  # 增加延迟间隔
	text_manager.max_texts_per_row = 3          # 减少每排文字数量

# 示例：清理所有飘字（在场景切换时使用）
func _on_scene_change():
	var text_manager = FloatingTextManager.get_instance()
	text_manager.clear_all_texts()