extends Node

# 多关卡管理器
# 用于管理多个随机关卡，并处理关卡之间的切换

# 预加载场景
var platform_scene = preload("res://scenes/platform.tscn")
var coin_scene = preload("res://scenes/coin.tscn")
var slime_scene = preload("res://scenes/slime.tscn")
var portal_scene = preload("res://scenes/portal.tscn") # 需要创建传送门场景

# 关卡参数
const TOTAL_LEVELS = 10 # 总关卡数
var current_level = 0 # 当前关卡索引
var level_seeds = [] # 关卡种子，用于确保每次生成相同的关卡

# 关卡区域定义
const ENTRANCE_AREA_START = Vector2(100, 250) # 入口区域起始位置
const MIDDLE_AREA_START = Vector2(400, 230) # 中间区域起始位置
const CHALLENGE_AREA_START = Vector2(800, 220) # 挑战区域起始位置
const TREASURE_AREA_START = Vector2(1200, 200) # 宝藏区域起始位置

# 关卡区域宽度
const AREA_WIDTH = 300

# 平台参数
const MIN_PLATFORM_SPACING = 80 # 平台之间的最小间距
const MAX_PLATFORM_SPACING = 150 # 平台之间的最大间距
const MIN_PLATFORM_HEIGHT = -30 # 高度变化范围
const MAX_PLATFORM_HEIGHT = 30 # 高度变化范围

# 金币和怪物参数
const COIN_HEIGHT_ABOVE_PLATFORM = 30 # 金币在平台上方的高度
const SLIME_HEIGHT_ABOVE_PLATFORM = 20 # 史莱姆在平台上方的高度

# 难度参数（随关卡增加而增加）
var moving_platform_chance = 0.1 # 移动平台概率
var purple_slime_chance = 0.0 # 紫色史莱姆概率
var slime_chance = 0.3 # 史莱姆出现概率

# 在准备好时调用
func _ready():
	# 初始化随机数生成器
	randomize()
	
	# 生成关卡种子
	_generate_level_seeds()
	
	# 生成第一个关卡
	generate_level(current_level)

# 生成关卡种子
func _generate_level_seeds():
	for i in range(TOTAL_LEVELS):
		level_seeds.append(randi())

# 生成指定索引的关卡
func generate_level(level_index):
	# 确保关卡索引有效
	if level_index < 0 or level_index >= TOTAL_LEVELS:
		return
	
	# 更新当前关卡索引
	current_level = level_index
	
	# 设置随机种子，确保每次生成相同的关卡
	seed(level_seeds[level_index])
	
	# 调整难度参数
	_adjust_difficulty(level_index)
	
	# 清除现有关卡元素
	_clear_level()
	
	# 创建关卡元素
	_create_random_entrance_area()
	_create_random_middle_area()
	_create_random_challenge_area()
	_create_random_treasure_area()
	
	# 创建出生点和终点
	_create_spawn_point()
	_create_level_exit()
	
	# 设置相机限制
	if has_node("Player") and $Player.has_node("Camera2D"):
		$Player/Camera2D.limit_left = 0
		$Player/Camera2D.limit_right = 1500
		$Player/Camera2D.limit_top = -300
		$Player/Camera2D.limit_bottom = 400
		
		# 设置相机缩放
		$Player/Camera2D.zoom = Vector2(1.5, 1.5)
	
	# 更新关卡信息标签
	_update_level_info()

# 调整难度参数
func _adjust_difficulty(level_index):
	# 根据关卡索引调整难度
	var difficulty_factor = float(level_index) / float(TOTAL_LEVELS - 1)
	
	# 调整移动平台概率 (0.1 到 0.7)
	moving_platform_chance = 0.1 + difficulty_factor * 0.6
	
	# 调整紫色史莱姆概率 (0.0 到 0.6)
	purple_slime_chance = difficulty_factor * 0.6
	
	# 调整史莱姆出现概率 (0.3 到 0.7)
	slime_chance = 0.3 + difficulty_factor * 0.4

# 创建出生点
func _create_spawn_point():
	# 将玩家移动到入口区域的起始位置
	if has_node("Player"):
		$Player.position = Vector2(50, 300)

# 创建关卡出口（传送门）
func _create_level_exit():
	# 创建传送门
	var portal = portal_scene.instantiate()
	portal.position = Vector2(TREASURE_AREA_START.x + 100, TREASURE_AREA_START.y - 50)
	
	# 设置传送门属性
	portal.connect("body_entered", _on_portal_body_entered)
	
	# 添加到场景
	add_child(portal)

# 当玩家进入传送门时调用
func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		# 如果不是最后一个关卡，则进入下一个关卡
		if current_level < TOTAL_LEVELS - 1:
			generate_level(current_level + 1)
		else:
			# 如果是最后一个关卡，则显示游戏通关信息
			_show_game_completed()

# 显示游戏通关信息
func _show_game_completed():
	# 创建通关标签
	var completion_label = Label.new()
	completion_label.text = "恭喜你通关了所有10个关卡！"
	completion_label.set_anchors_preset(Control.PRESET_CENTER)
	completion_label.add_theme_font_size_override("font_size", 24)
	
	# 添加到UI
	if has_node("UI"):
		$UI.add_child(completion_label)

# 更新关卡信息标签
func _update_level_info():
	# 更新关卡信息
	if has_node("LevelInfo"):
		$LevelInfo.text = "关卡: %d/%d" % [current_level + 1, TOTAL_LEVELS]

# 清除现有关卡元素
func _clear_level():
	# 清除平台
	if has_node("Platforms"):
		for child in $Platforms.get_children():
			child.queue_free()
	
	# 清除金币
	if has_node("Coins"):
		for child in $Coins.get_children():
			child.queue_free()
	
	# 清除怪物
	if has_node("Monsters"):
		for child in $Monsters.get_children():
			child.queue_free()
	
	# 清除传送门
	for child in get_children():
		if child.is_in_group("portal"):
			child.queue_free()

# 创建随机入口区域
func _create_random_entrance_area():
	# 入口区域平台数量 (3-5个)
	var platform_count = randi_range(3, 5)
	
	# 创建平台
	var platforms = _generate_platforms(ENTRANCE_AREA_START, platform_count, moving_platform_chance * 0.5)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.8)
	_place_coins_on_platforms(platforms, 0.8)
	
	# 在平台上放置史莱姆 (根据难度调整)
	_place_slimes_on_platforms(platforms, slime_chance * 0.5, purple_slime_chance * 0.5)

# 创建随机中间区域
func _create_random_middle_area():
	# 中间区域平台数量 (4-6个)
	var platform_count = randi_range(4, 6)
	
	# 创建平台
	var platforms = _generate_platforms(MIDDLE_AREA_START, platform_count, moving_platform_chance)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.7)
	_place_coins_on_platforms(platforms, 0.7)
	
	# 在平台上放置史莱姆 (根据难度调整)
	_place_slimes_on_platforms(platforms, slime_chance, purple_slime_chance)

# 创建随机挑战区域
func _create_random_challenge_area():
	# 挑战区域平台数量 (5-7个)
	var platform_count = randi_range(5, 7)
	
	# 创建平台
	var platforms = _generate_platforms(CHALLENGE_AREA_START, platform_count, moving_platform_chance * 1.5)
	
	# 在平台上放置金币 (每个平台1个金币的概率为0.6)
	_place_coins_on_platforms(platforms, 0.6)
	
	# 在平台上放置史莱姆 (根据难度调整)
	_place_slimes_on_platforms(platforms, slime_chance * 1.5, purple_slime_chance * 1.5)
	
	# 添加一些隐藏金币
	_add_hidden_coins(platforms, 2)

# 创建随机宝藏区域
func _create_random_treasure_area():
	# 宝藏区域平台数量 (3个)
	var platform_count = 3
	
	# 创建平台
	var platforms = _generate_platforms(TREASURE_AREA_START, platform_count, 0.0) # 宝藏区域不使用移动平台
	
	# 在平台上放置金币 (每个平台上都有金币)
	_place_coins_on_platforms(platforms, 1.0)
	
	# 额外添加金币，形成皇冠形状
	_create_crown_shaped_coins(TREASURE_AREA_START)
	
	# 在中间平台上放置紫色史莱姆作为Boss
	if platforms.size() > 0:
		_create_slime(Vector2(platforms[platforms.size()/2].position.x, 
					 platforms[platforms.size()/2].position.y - SLIME_HEIGHT_ABOVE_PLATFORM), true)

# 生成平台
func _generate_platforms(start_pos, count, moving_chance):
	var platforms = []
	var current_pos = start_pos
	
	for i in range(count):
		# 随机决定平台位置
		var platform_pos = Vector2(
			current_pos.x + randf_range(MIN_PLATFORM_SPACING, MAX_PLATFORM_SPACING),
			current_pos.y + randf_range(MIN_PLATFORM_HEIGHT, MAX_PLATFORM_HEIGHT)
		)
		
		# 确保平台不会太高或太低
		platform_pos.y = clamp(platform_pos.y, 150, 280) # 调整高度范围，使平台分布更合理
		
		# 随机决定是否为移动平台
		var is_moving = randf() < moving_chance
		
		# 创建平台
		var platform = _create_platform(platform_pos, is_moving)
		platforms.append(platform)
		
		# 更新当前位置
		current_pos = platform_pos
	
	return platforms

# 在平台上放置金币
func _place_coins_on_platforms(platforms, coin_chance):
	for platform in platforms:
		# 随机决定是否在此平台上放置金币
		if randf() < coin_chance:
			_create_coin(Vector2(
				platform.position.x,
				platform.position.y - COIN_HEIGHT_ABOVE_PLATFORM
			))

# 在平台上放置史莱姆
func _place_slimes_on_platforms(platforms, slime_spawn_chance, purple_spawn_chance):
	for platform in platforms:
		# 随机决定是否在此平台上放置史莱姆
		if randf() < slime_spawn_chance:
			# 随机决定是否为紫色史莱姆
			var is_purple = randf() < purple_spawn_chance
			
			_create_slime(Vector2(
				platform.position.x,
				platform.position.y - SLIME_HEIGHT_ABOVE_PLATFORM
			), is_purple)

# 添加隐藏金币
func _add_hidden_coins(platforms, count):
	for i in range(count):
		# 随机选择一个平台
		if platforms.size() > 0:
			var platform = platforms[randi() % platforms.size()]
			
			# 在平台附近的随机位置创建金币
			_create_coin(Vector2(
				platform.position.x + randf_range(-30, 30),
				platform.position.y - randf_range(50, 80)
			))

# 创建皇冠形状的金币
func _create_crown_shaped_coins(center_pos):
	# 创建皇冠顶部的金币
	_create_coin(Vector2(center_pos.x, center_pos.y - 60))
	
	# 创建皇冠左侧的金币
	_create_coin(Vector2(center_pos.x - 20, center_pos.y - 50))
	_create_coin(Vector2(center_pos.x - 40, center_pos.y - 40))
	
	# 创建皇冠右侧的金币
	_create_coin(Vector2(center_pos.x + 20, center_pos.y - 50))
	_create_coin(Vector2(center_pos.x + 40, center_pos.y - 40))

# 创建平台
func _create_platform(pos, is_moving = false):
	var platform = platform_scene.instantiate()
	platform.position = pos
	
	if is_moving:
		# 添加动画播放器
		var anim_player = AnimationPlayer.new()
		platform.add_child(anim_player)
		
		# 创建移动动画
		var animation = Animation.new()
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, ":position")
		
		# 随机决定移动方向（水平或垂直）
		var is_horizontal = randf() < 0.7 # 70%概率水平移动
		var move_distance = randf_range(40, 80)
		
		if is_horizontal:
			# 水平移动
			animation.track_insert_key(track_index, 0.0, Vector2(0, 0))
			animation.track_insert_key(track_index, 1.3, Vector2(move_distance, 0))
		else:
			# 垂直移动
			animation.track_insert_key(track_index, 0.0, Vector2(0, 0))
			animation.track_insert_key(track_index, 1.3, Vector2(0, move_distance))
		
		animation.set_length(2.6)
		animation.set_loop_mode(Animation.LOOP_PINGPONG)
		
		# 将动画添加到播放器
		var anim_lib = AnimationLibrary.new()
		anim_lib.add_animation("move", animation)
		anim_player.add_animation_library("default", anim_lib)
		anim_player.play("default/move")
	
	# 添加到场景
	if not has_node("Platforms"):
		var platforms = Node2D.new()
		platforms.name = "Platforms"
		add_child(platforms)
	
	$Platforms.add_child(platform)
	return platform

# 创建金币
func _create_coin(pos):
	var coin = coin_scene.instantiate()
	coin.position = pos
	
	# 添加到场景
	if not has_node("Coins"):
		var coins = Node2D.new()
		coins.name = "Coins"
		add_child(coins)
	
	$Coins.add_child(coin)
	return coin

# 创建史莱姆敌人
func _create_slime(pos, is_purple = false):
	var slime = slime_scene.instantiate()
	slime.position = pos
	
	# 如果是紫色史莱姆，修改精灵图像和速度
	if is_purple:
		var animated_sprite = slime.get_node("AnimatedSprite2D")
		animated_sprite.sprite_frames.set_animation_speed("default", 10) # 增加动画速度
		
		# 加载紫色史莱姆纹理
		var texture = load("res://assets/sprites/slime_purple.png")
		for i in range(animated_sprite.sprite_frames.get_frame_count("default")):
			var atlas_texture = animated_sprite.sprite_frames.get_frame_texture("default", i)
			var new_atlas_texture = AtlasTexture.new()
			new_atlas_texture.atlas = texture
			new_atlas_texture.region = atlas_texture.region
			animated_sprite.sprite_frames.set_frame("default", i, new_atlas_texture)
		
		# 增加移动速度
		slime.SPEED = 60 # 比普通史莱姆快
	
	# 添加到场景
	if not has_node("Monsters"):
		var monsters = Node2D.new()
		monsters.name = "Monsters"
		add_child(monsters)
	
	$Monsters.add_child(slime)
	return slime