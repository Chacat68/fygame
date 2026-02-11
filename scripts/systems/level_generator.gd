# 通用关卡生成器
# 从JSON数据文件动态生成关卡场景
class_name LevelGenerator
extends Node

# 场景缓存字典
var _scene_cache: Dictionary = {}

# 预加载实体场景
func _ready():
	_preload_scenes()

# 预加载所有实体场景到缓存
func _preload_scenes():
	_scene_cache["player"] = preload("res://scenes/entities/player.tscn")
	_scene_cache["coin"] = preload("res://scenes/entities/coin.tscn")
	_scene_cache["platform"] = preload("res://scenes/entities/platform.tscn")
	_scene_cache["slime"] = preload("res://scenes/entities/slime.tscn")
	_scene_cache["killzone"] = preload("res://scenes/entities/killzone.tscn")
	_scene_cache["portal"] = preload("res://scenes/entities/portal.tscn")
	_scene_cache["game_manager"] = preload("res://scenes/managers/game_manager.tscn")
	_scene_cache["ui"] = preload("res://scenes/ui/ui.tscn")
	print("[LevelGenerator] 场景预加载完成")

# 从JSON文件生成关卡
func generate_level_from_file(json_path: String) -> Node2D:
	var data = _load_json(json_path)
	if data.is_empty():
		push_error("[LevelGenerator] 无法加载关卡数据: " + json_path)
		return null
	return generate_level(data)

# 从Dictionary数据生成关卡
func generate_level(data: Dictionary) -> Node2D:
	if data.is_empty():
		push_error("[LevelGenerator] 关卡数据为空")
		return null
	
	print("[LevelGenerator] 开始生成关卡: ", data.get("level_name", "未命名"))
	
	# 创建根节点
	var root = Node2D.new()
	root.name = "Level%d" % data.get("level_id", 0)
	
	# 按顺序创建关卡元素
	_create_game_manager(root)
	_create_ui(root)
	
	# 加载TileMap（如果有）
	if data.has("tilemap_scene"):
		_create_tilemap(root, data["tilemap_scene"])
	
	# 创建玩家
	if data.has("player"):
		_create_player(root, data["player"])
	
	# 创建相机
	if data.has("camera"):
		_create_camera(root, data["camera"])
	
	# 创建killzone
	if data.has("killzone"):
		_create_killzone(root, data["killzone"])
	
	# 创建金币
	if data.has("coins"):
		_create_coins(root, data["coins"])
	
	# 创建平台
	if data.has("platforms"):
		_create_platforms(root, data["platforms"])
	
	# 创建敌人
	if data.has("enemies"):
		_create_enemies(root, data["enemies"])
	
	# 创建传送门
	if data.has("portal"):
		_create_portal(root, data["portal"])
	
	print("[LevelGenerator] 关卡生成完成: ", root.name)
	return root

# 加载JSON文件
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[LevelGenerator] JSON文件不存在: " + path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[LevelGenerator] 无法打开JSON文件: " + path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("[LevelGenerator] JSON解析错误 (行 %d): %s" % [json.get_error_line(), json.get_error_message()])
		return {}
	
	return json.data

# 创建游戏管理器
func _create_game_manager(root: Node2D):
	if not _scene_cache.has("game_manager"):
		push_error("[LevelGenerator] GameManager场景未缓存")
		return
	
	var game_manager = _scene_cache["game_manager"].instantiate()
	game_manager.name = "GameManager"
	root.add_child(game_manager)
	
	# 附加脚本（场景中应该已经有了，这里是确保）
	if not game_manager.get_script():
		var script = load("res://scripts/managers/game_manager.gd")
		game_manager.set_script(script)
	
	print("[LevelGenerator] GameManager创建完成")

# 创建UI
func _create_ui(root: Node2D):
	if not _scene_cache.has("ui"):
		push_error("[LevelGenerator] UI场景未缓存")
		return
	
	var ui = _scene_cache["ui"].instantiate()
	ui.name = "UI"
	root.add_child(ui)
	print("[LevelGenerator] UI创建完成")

# 创建玩家
func _create_player(root: Node2D, player_data: Dictionary):
	if not _scene_cache.has("player"):
		push_error("[LevelGenerator] Player场景未缓存")
		return
	
	var player = _scene_cache["player"].instantiate()
	player.name = "Player"
	
	# 设置位置
	if player_data.has("position"):
		var pos = player_data["position"]
		player.position = Vector2(pos[0], pos[1])
	
	root.add_child(player)
	print("[LevelGenerator] Player创建完成，位置: ", player.position)

# 创建相机
func _create_camera(root: Node2D, cam_data: Dictionary):
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	
	# 设置位置
	if cam_data.has("position"):
		var pos = cam_data["position"]
		camera.position = Vector2(pos[0], pos[1])
	
	# 设置缩放
	if cam_data.has("zoom"):
		var zoom = cam_data["zoom"]
		camera.zoom = Vector2(zoom[0], zoom[1])
	
	# 设置限制
	if cam_data.has("limit_left"):
		camera.limit_left = cam_data["limit_left"]
	if cam_data.has("limit_bottom"):
		camera.limit_bottom = cam_data["limit_bottom"]
	
	# 设置平滑
	if cam_data.has("smooth"):
		camera.position_smoothing_enabled = cam_data["smooth"]
	
	root.add_child(camera)
	print("[LevelGenerator] Camera2D创建完成")

# 创建killzone
func _create_killzone(root: Node2D, kz_data: Dictionary):
	if not _scene_cache.has("killzone"):
		push_error("[LevelGenerator] Killzone场景未缓存")
		return
	
	var killzone = _scene_cache["killzone"].instantiate()
	killzone.name = "Killzone"
	
	# 设置y位置
	if kz_data.has("y_position"):
		killzone.position.y = kz_data["y_position"]
	
	# 添加碰撞形状
	var collision_shape = CollisionShape2D.new()
	var shape = WorldBoundaryShape2D.new()
	shape.normal = Vector2(0, -1)  # 向上的法线
	collision_shape.shape = shape
	killzone.add_child(collision_shape)
	
	root.add_child(killzone)
	print("[LevelGenerator] Killzone创建完成，y位置: ", killzone.position.y)

# 从子场景路径加载TileMap
func _create_tilemap(root: Node2D, tilemap_scene_path: String):
	if not ResourceLoader.exists(tilemap_scene_path):
		push_warning("[LevelGenerator] TileMap场景不存在: " + tilemap_scene_path)
		return
	
	# 加载场景并提取TileMap节点
	var tilemap_scene = load(tilemap_scene_path)
	if tilemap_scene:
		var scene_instance = tilemap_scene.instantiate()
		
		# 查找TileMap节点
		var tilemap = null
		for child in scene_instance.get_children():
			if child is TileMap:
				tilemap = child
				break
		
		if tilemap:
			# 从原场景中移除并添加到新关卡
			scene_instance.remove_child(tilemap)
			root.add_child(tilemap)
			print("[LevelGenerator] TileMap加载完成")
		else:
			push_warning("[LevelGenerator] 在场景中未找到TileMap: " + tilemap_scene_path)
		
		# 清理临时场景实例
		scene_instance.queue_free()

# 创建金币
func _create_coins(root: Node2D, coins_data: Array):
	if not _scene_cache.has("coin"):
		push_error("[LevelGenerator] Coin场景未缓存")
		return
	
	# 创建Coins容器
	var coins_container = Node2D.new()
	coins_container.name = "Coins"
	root.add_child(coins_container)
	
	# 遍历创建金币
	for coin_data in coins_data:
		var coin = _scene_cache["coin"].instantiate()
		
		if coin_data.has("position"):
			var pos = coin_data["position"]
			coin.position = Vector2(pos[0], pos[1])
		
		coins_container.add_child(coin)
	
	print("[LevelGenerator] 创建了 %d 个金币" % coins_data.size())

# 创建平台
func _create_platforms(root: Node2D, platforms_data: Array):
	if not _scene_cache.has("platform"):
		push_error("[LevelGenerator] Platform场景未缓存")
		return
	
	# 创建Platforms容器
	var platforms_container = Node2D.new()
	platforms_container.name = "Platforms"
	root.add_child(platforms_container)
	
	# 遍历创建平台
	for platform_data in platforms_data:
		var platform = _scene_cache["platform"].instantiate()
		
		if platform_data.has("position"):
			var pos = platform_data["position"]
			platform.position = Vector2(pos[0], pos[1])
		
		# 检查是否为移动平台
		if platform_data.get("is_moving", false):
			_setup_moving_platform(platform, platform_data)
		
		platforms_container.add_child(platform)
	
	print("[LevelGenerator] 创建了 %d 个平台" % platforms_data.size())

# 设置移动平台
func _setup_moving_platform(platform: Node, platform_data: Dictionary):
	# 创建AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	platform.add_child(anim_player)
	
	# 创建AnimationLibrary
	var anim_lib = AnimationLibrary.new()
	
	# 创建RESET动画
	var reset_anim = Animation.new()
	reset_anim.length = 0.001
	var reset_track = reset_anim.add_track(Animation.TYPE_VALUE)
	reset_anim.track_set_path(reset_track, ":position")
	reset_anim.track_insert_key(reset_track, 0.0, Vector2.ZERO)
	anim_lib.add_animation("RESET", reset_anim)
	
	# 创建move动画
	var move_anim = Animation.new()
	var move_duration = platform_data.get("move_duration", 1.3)
	move_anim.length = move_duration * 2  # pingpong需要双倍长度
	
	var move_track = move_anim.add_track(Animation.TYPE_VALUE)
	move_anim.track_set_path(move_track, ":position")
	
	# 获取移动目标
	var move_target = Vector2.ZERO
	if platform_data.has("move_target"):
		var target = platform_data["move_target"]
		move_target = Vector2(target[0], target[1]) - Vector2(platform_data["position"][0], platform_data["position"][1])
	
	# 插入关键帧
	move_anim.track_insert_key(move_track, 0.0, Vector2.ZERO)
	move_anim.track_insert_key(move_track, move_duration, move_target)
	
	# 设置循环模式
	var loop_mode = platform_data.get("loop_mode", "pingpong")
	if loop_mode == "pingpong":
		move_anim.loop_mode = Animation.LOOP_PINGPONG
	else:
		move_anim.loop_mode = Animation.LOOP_LINEAR
	
	anim_lib.add_animation("move", move_anim)
	
	# 添加库到播放器
	anim_player.add_animation_library("", anim_lib)
	
	# 播放动画
	anim_player.play("move")
	
	print("[LevelGenerator] 设置移动平台: 目标=%s, 时长=%s" % [move_target, move_duration])

# 创建敌人
func _create_enemies(root: Node2D, enemies_data: Array):
	# 创建Monster容器
	var monsters_container = Node2D.new()
	monsters_container.name = "Monster"
	root.add_child(monsters_container)
	
	# 遍历创建敌人
	for enemy_data in enemies_data:
		var enemy_type = enemy_data.get("type", "slime")
		
		# 根据类型获取对应场景
		if not _scene_cache.has(enemy_type):
			push_warning("[LevelGenerator] 未知敌人类型: " + enemy_type)
			continue
		
		var enemy = _scene_cache[enemy_type].instantiate()
		
		if enemy_data.has("position"):
			var pos = enemy_data["position"]
			enemy.position = Vector2(pos[0], pos[1])
		
		monsters_container.add_child(enemy)
	
	print("[LevelGenerator] 创建了 %d 个敌人" % enemies_data.size())

# 创建传送门
func _create_portal(root: Node2D, portal_data: Dictionary):
	if not _scene_cache.has("portal"):
		push_error("[LevelGenerator] Portal场景未缓存")
		return
	
	var portal = _scene_cache["portal"].instantiate()
	portal.name = "Portal"
	
	# 设置位置
	if portal_data.has("position"):
		var pos = portal_data["position"]
		portal.position = Vector2(pos[0], pos[1])
	
	root.add_child(portal)
	
	# 配置目标场景（使用call_deferred确保portal的_ready已执行）
	if portal_data.has("destination_scene"):
		var dest = portal_data["destination_scene"]
		portal.call_deferred("configure_for_scene_teleport", dest)
		print("[LevelGenerator] Portal创建完成，目标: ", dest)
	else:
		print("[LevelGenerator] Portal创建完成（无目标配置）")
