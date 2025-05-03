extends Node2D

# 预加载场景
var platform_scene = preload("res://scenes/platform.tscn")
var coin_scene = preload("res://scenes/coin.tscn")
var slime_scene = preload("res://scenes/slime.tscn")

# 在准备好时调用
func _ready():
	# 创建关卡元素
	_create_entrance_area()
	_create_middle_area()
	_create_challenge_area()
	_create_treasure_area()
	
	# 设置相机限制
	if has_node("Player") and $Player.has_node("Camera2D"):
		$Player/Camera2D.limit_left = 0
		$Player/Camera2D.limit_right = 1500
		$Player/Camera2D.limit_top = -300
		$Player/Camera2D.limit_bottom = 400

# 创建入口区域（教学区）
func _create_entrance_area():
	# 创建平台
	_create_platform(Vector2(200, 320), false) # 左侧平台
	_create_platform(Vector2(280, 280), false) # 中间平台
	_create_platform(Vector2(360, 320), false) # 右侧平台
	
	# 放置金币
	_create_coin(Vector2(280, 250)) # 中间平台上方
	_create_coin(Vector2(200, 290)) # 左侧平台上方
	_create_coin(Vector2(360, 290)) # 右侧平台上方
	_create_coin(Vector2(240, 260)) # 左中间
	_create_coin(Vector2(320, 260)) # 右中间
	
	# 放置史莱姆敌人
	_create_slime(Vector2(280, 260), false) # 中间平台上的敌人

# 创建中间区域（逐渐增加难度）
func _create_middle_area():
	# 创建平台
	_create_platform(Vector2(480, 280), false) # 左侧平台
	_create_platform(Vector2(560, 240), false) # 中间平台
	_create_platform(Vector2(640, 280), true) # 右侧移动平台
	_create_platform(Vector2(720, 240), false) # 最右侧平台
	
	# 放置金币
	_create_coin(Vector2(480, 250)) # 左侧平台上方
	_create_coin(Vector2(520, 250)) # 左侧和中间平台之间
	_create_coin(Vector2(560, 210)) # 中间平台上方
	_create_coin(Vector2(640, 250)) # 右侧移动平台上方
	_create_coin(Vector2(680, 250)) # 右侧移动平台和最右侧平台之间
	_create_coin(Vector2(720, 210)) # 最右侧平台上方
	_create_coin(Vector2(760, 210)) # 最右侧平台右边
	_create_coin(Vector2(600, 210)) # 中间和右侧平台之间
	
	# 放置史莱姆敌人
	_create_slime(Vector2(560, 220), false) # 中间平台上的敌人
	_create_slime(Vector2(720, 220), false) # 最右侧平台上的敌人

# 创建挑战区域（高难度）
func _create_challenge_area():
	# 创建平台
	_create_platform(Vector2(840, 280), false) # 左下平台
	_create_platform(Vector2(900, 240), true) # 中下移动平台
	_create_platform(Vector2(960, 200), false) # 中上平台
	_create_platform(Vector2(1020, 240), true) # 右上移动平台
	_create_platform(Vector2(1080, 280), false) # 右下平台
	
	# 放置金币
	_create_coin(Vector2(840, 250)) # 左下平台上方
	_create_coin(Vector2(900, 210)) # 中下移动平台上方
	_create_coin(Vector2(960, 170)) # 中上平台上方
	_create_coin(Vector2(1020, 210)) # 右上移动平台上方
	_create_coin(Vector2(1080, 250)) # 右下平台上方
	_create_coin(Vector2(880, 170)) # 左侧高处隐藏金币
	_create_coin(Vector2(1040, 170)) # 右侧高处隐藏金币
	
	# 放置史莱姆敌人
	_create_slime(Vector2(960, 180), false) # 中上平台上的敌人
	_create_slime(Vector2(1020, 220), false) # 右上移动平台上的敌人
	_create_slime(Vector2(1080, 260), true) # 右下平台上的紫色史莱姆

# 创建宝藏区域（终点）
func _create_treasure_area():
	# 创建平台
	_create_platform(Vector2(1200, 240), false) # 中间平台
	_create_platform(Vector2(1160, 280), false) # 左侧平台
	_create_platform(Vector2(1240, 280), false) # 右侧平台
	
	# 放置金币
	_create_coin(Vector2(1180, 210)) # 中间平台左侧上方
	_create_coin(Vector2(1200, 210)) # 中间平台中间上方
	_create_coin(Vector2(1220, 210)) # 中间平台右侧上方
	_create_coin(Vector2(1160, 250)) # 左侧平台上方
	_create_coin(Vector2(1240, 250)) # 右侧平台上方
	
	# 放置史莱姆敌人（增强版）
	_create_slime(Vector2(1200, 220), true) # 中间平台上的紫色史莱姆

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
