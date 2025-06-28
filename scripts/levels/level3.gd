extends Node2D

# 预加载场景
var platform_scene = preload("res://scenes/entities/platform.tscn")
var coin_scene = preload("res://scenes/entities/coin.tscn")
var slime_scene = preload("res://scenes/entities/slime.tscn")

# 在准备好时调用
func _ready():
	# 创建关卡元素
	_create_entrance_area()
	_create_middle_area()
	_create_challenge_area()
	_create_treasure_area()
	
	# 相机限制已在player.tscn中设置，无需重复设置

# 创建入口区域（第三关特色设计）
func _create_entrance_area():
	# 创建阶梯式平台
	_create_platform(Vector2(180, 340), false) # 最低平台
	_create_platform(Vector2(260, 300), false) # 中低平台
	_create_platform(Vector2(340, 260), false) # 中高平台
	_create_platform(Vector2(420, 220), false) # 最高平台
	
	# 放置金币（阶梯式收集）
	_create_coin(Vector2(180, 310)) # 最低平台上方
	_create_coin(Vector2(220, 280)) # 平台间隙
	_create_coin(Vector2(260, 270)) # 中低平台上方
	_create_coin(Vector2(300, 240)) # 平台间隙
	_create_coin(Vector2(340, 230)) # 中高平台上方
	_create_coin(Vector2(380, 200)) # 平台间隙
	_create_coin(Vector2(420, 190)) # 最高平台上方
	
	# 放置史莱姆敌人
	_create_slime(Vector2(260, 280), false) # 中低平台上的敌人
	_create_slime(Vector2(420, 200), false) # 最高平台上的敌人

# 创建中间区域（跳跃挑战区）
func _create_middle_area():
	# 创建跳跃挑战平台
	_create_platform(Vector2(520, 300), false) # 起始平台
	_create_platform(Vector2(600, 260), true) # 第一个移动平台
	_create_platform(Vector2(700, 220), false) # 中间休息平台
	_create_platform(Vector2(800, 180), true) # 第二个移动平台
	_create_platform(Vector2(900, 240), false) # 终点平台
	
	# 放置金币（跳跃路径）
	_create_coin(Vector2(520, 270)) # 起始平台上方
	_create_coin(Vector2(560, 240)) # 跳跃间隙
	_create_coin(Vector2(600, 230)) # 第一个移动平台上方
	_create_coin(Vector2(650, 200)) # 跳跃间隙
	_create_coin(Vector2(700, 190)) # 中间休息平台上方
	_create_coin(Vector2(750, 160)) # 跳跃间隙
	_create_coin(Vector2(800, 150)) # 第二个移动平台上方
	_create_coin(Vector2(850, 220)) # 跳跃间隙
	_create_coin(Vector2(900, 210)) # 终点平台上方
	
	# 放置史莱姆敌人（跳跃挑战）
	_create_slime(Vector2(700, 200), false) # 中间休息平台上的敌人
	_create_slime(Vector2(900, 220), true) # 终点平台上的紫色史莱姆

# 创建挑战区域（垂直迷宫）
func _create_challenge_area():
	# 创建垂直迷宫式平台
	_create_platform(Vector2(1000, 320), false) # 底层入口
	_create_platform(Vector2(1080, 280), true) # 第一层移动平台
	_create_platform(Vector2(1000, 240), false) # 第二层左侧
	_create_platform(Vector2(1120, 240), false) # 第二层右侧
	_create_platform(Vector2(1060, 200), true) # 第三层移动平台
	_create_platform(Vector2(1000, 160), false) # 第四层左侧
	_create_platform(Vector2(1120, 160), false) # 第四层右侧
	_create_platform(Vector2(1060, 120), false) # 顶层平台
	
	# 放置金币（垂直收集路径）
	_create_coin(Vector2(1000, 290)) # 底层入口上方
	_create_coin(Vector2(1080, 250)) # 第一层移动平台上方
	_create_coin(Vector2(1000, 210)) # 第二层左侧上方
	_create_coin(Vector2(1120, 210)) # 第二层右侧上方
	_create_coin(Vector2(1060, 170)) # 第三层移动平台上方
	_create_coin(Vector2(1000, 130)) # 第四层左侧上方
	_create_coin(Vector2(1120, 130)) # 第四层右侧上方
	_create_coin(Vector2(1060, 90)) # 顶层平台上方
	_create_coin(Vector2(1040, 180)) # 隐藏金币1
	_create_coin(Vector2(1080, 140)) # 隐藏金币2
	
	# 放置史莱姆敌人（垂直守卫）
	_create_slime(Vector2(1080, 260), false) # 第一层移动平台上的敌人
	_create_slime(Vector2(1000, 220), false) # 第二层左侧敌人
	_create_slime(Vector2(1120, 220), true) # 第二层右侧紫色史莱姆
	_create_slime(Vector2(1060, 180), false) # 第三层移动平台上的敌人
	_create_slime(Vector2(1060, 100), true) # 顶层平台上的紫色史莱姆

# 创建宝藏区域（最终挑战）
func _create_treasure_area():
	# 创建最终挑战平台
	_create_platform(Vector2(1200, 300), false) # 入口平台
	_create_platform(Vector2(1280, 260), true) # 左侧移动平台
	_create_platform(Vector2(1360, 220), false) # 中央高台
	_create_platform(Vector2(1440, 260), true) # 右侧移动平台
	_create_platform(Vector2(1520, 300), false) # 终点平台
	_create_platform(Vector2(1360, 180), false) # 奖励高台
	
	# 放置金币（最终奖励）
	_create_coin(Vector2(1200, 270)) # 入口平台上方
	_create_coin(Vector2(1240, 240)) # 跳跃间隙
	_create_coin(Vector2(1280, 230)) # 左侧移动平台上方
	_create_coin(Vector2(1320, 200)) # 跳跃间隙
	_create_coin(Vector2(1360, 190)) # 中央高台上方
	_create_coin(Vector2(1400, 200)) # 跳跃间隙
	_create_coin(Vector2(1440, 230)) # 右侧移动平台上方
	_create_coin(Vector2(1480, 240)) # 跳跃间隙
	_create_coin(Vector2(1520, 270)) # 终点平台上方
	_create_coin(Vector2(1360, 150)) # 奖励高台上方（特殊奖励）
	_create_coin(Vector2(1340, 150)) # 奖励高台左侧
	_create_coin(Vector2(1380, 150)) # 奖励高台右侧
	
	# 放置史莱姆敌人（最终Boss战）
	_create_slime(Vector2(1280, 240), true) # 左侧移动平台上的紫色史莱姆
	_create_slime(Vector2(1360, 200), true) # 中央高台上的紫色史莱姆（Boss）
	_create_slime(Vector2(1440, 240), true) # 右侧移动平台上的紫色史莱姆

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
		animation.track_insert_key(track_index, 0.0, Vector2(0, 0))
		animation.track_insert_key(track_index, 1.3, Vector2(60, 0)) # 水平移动
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