extends Node

# 程序化地形生成和房间系统
# 用于在随机关卡生成器中实现《缺氧》风格的房间和走廊系统

# 预加载房间配置资源
var room_config = preload("res://scripts/room_config.gd").new()

# 房间类型枚举 - 从配置文件中导入以保持一致性
enum RoomType {
	ENTRANCE = 0,  # 入口房间
	CORRIDOR = 1,  # 走廊房间
	STORAGE = 2,   # 储藏室
	OXYGEN = 3,    # 氧气房间
	CHALLENGE = 4, # 挑战房间
	TREASURE = 5   # 宝藏房间
}

# 房间参数
var min_room_size = Vector2(150, 150)
var max_room_size = Vector2(300, 300)
var min_corridor_width = 80
var max_corridor_width = 120
var min_corridor_length = 100
var max_corridor_length = 250
var room_spacing = 50

# 房间布局参数
var level_width = 1500
var level_height = 600
var max_rooms = 8
var min_rooms = 5

# 生成基于房间的关卡
func _generate_room_based_level(biome_type):
	# 创建房间容器节点
	if not has_node("Rooms"):
		var rooms_node = Node2D.new()
		rooms_node.name = "Rooms"
		add_child(rooms_node)
	
	# 创建走廊容器节点
	if not has_node("Corridors"):
		var corridors_node = Node2D.new()
		corridors_node.name = "Corridors"
		add_child(corridors_node)
	
	# 确定房间数量（根据关卡难度调整）
	var room_count = min_rooms + randi() % (max_rooms - min_rooms + 1)
	
	# 生成房间
	var rooms = []
	var room_rects = []
	
	# 首先创建入口房间（左侧）
	var entrance_room = _create_room(
		Rect2(100, 200, 200, 200),
		RoomType.ENTRANCE,
		biome_type
	)
	rooms.append(entrance_room)
	room_rects.append(Rect2(100, 200, 200, 200))
	
	# 最后创建宝藏房间（右侧）
	var treasure_room = _create_room(
		Rect2(level_width - 300, 200, 200, 200),
		RoomType.TREASURE,
		biome_type
	)
	rooms.append(treasure_room)
	room_rects.append(Rect2(level_width - 300, 200, 200, 200))
	
	# 创建中间房间
	for i in range(room_count - 2):
		# 尝试放置房间，确保不重叠
		var attempts = 0
		var room_placed = false
		
		while attempts < 20 and not room_placed:
			# 随机房间大小
			var room_width = min_room_size.x + randi() % int(max_room_size.x - min_room_size.x)
			var room_height = min_room_size.y + randi() % int(max_room_size.y - min_room_size.y)
			
			# 随机位置（确保在关卡范围内）
			var x = 300 + randi() % int(level_width - 600 - room_width)
			var y = 100 + randi() % int(level_height - 200 - room_height)
			
			# 创建房间矩形
			var new_rect = Rect2(x, y, room_width, room_height)
			
			# 检查是否与现有房间重叠
			var overlaps = false
			for existing_rect in room_rects:
				# 扩展现有矩形以考虑间距
				var expanded_rect = Rect2(
					existing_rect.position.x - room_spacing,
					existing_rect.position.y - room_spacing,
					existing_rect.size.x + room_spacing * 2,
					existing_rect.size.y + room_spacing * 2
				)
				
				if expanded_rect.intersects(new_rect):
					overlaps = true
					break
			
			if not overlaps:
				# 确定房间类型
				var room_type
				var type_roll = randi() % 10
				
				if type_roll < 3:
					room_type = RoomType.STORAGE
				elif type_roll < 6:
					room_type = RoomType.OXYGEN
				else:
					room_type = RoomType.CHALLENGE
				
				# 创建房间
				var room = _create_room(new_rect, room_type, biome_type)
				rooms.append(room)
				room_rects.append(new_rect)
				room_placed = true
			
			attempts += 1
	
	# 连接房间（创建走廊）
	_connect_rooms(rooms, room_rects, biome_type)
	
	# 在房间内放置平台、金币和敌人
	_populate_rooms(rooms, room_rects, biome_type)

# 创建单个房间
func _create_room(rect, room_type, biome_type):
	# 获取房间配置
	var config = room_config.get_room_config(room_type, biome_type)
	
	# 创建房间节点
	var room = ColorRect.new()
	room.name = "Room_" + str(room_type)
	room.position = rect.position
	room.size = rect.size
	
	# 设置房间颜色（已应用生物群系修改）
	room.color = config.color
	
	# 设置元数据
	room.set_meta("type", room_type)
	room.set_meta("rect", rect)
	room.set_meta("config", config)
	
	# 添加到房间组
	room.add_to_group("rooms")
	
	# 添加到场景
	$Rooms.add_child(room)
	
	# 添加房间标签
	var label = Label.new()
	label.text = config.name
	label.position = Vector2(rect.size.x / 2 - 20, rect.size.y / 2 - 10)
	room.add_child(label)
	
	return room

# 连接房间（创建走廊）
func _connect_rooms(rooms, room_rects, biome_type):
	# 使用最小生成树算法连接所有房间
	var connected = [0]  # 从第一个房间开始
	var unconnected = []
	
	# 初始化未连接房间列表
	for i in range(1, rooms.size()):
		unconnected.append(i)
	
	# 连接所有房间
	while unconnected.size() > 0:
		var min_dist = INF
		var closest_connected = -1
		var closest_unconnected = -1
		
		# 找到最近的未连接房间
		for c in connected:
			for u in unconnected:
				# 计算房间中心点之间的距离
				var center1 = room_rects[c].position + room_rects[c].size / 2
				var center2 = room_rects[u].position + room_rects[u].size / 2
				var dist = center1.distance_to(center2)
				
				if dist < min_dist:
					min_dist = dist
					closest_connected = c
					closest_unconnected = u
		
		# 创建走廊连接这两个房间
		_create_corridor(room_rects[closest_connected], room_rects[closest_unconnected], closest_connected, closest_unconnected, biome_type)
		
		# 更新连接状态
		connected.append(closest_unconnected)
		unconnected.erase(closest_unconnected)
	
	# 添加一些额外的走廊以创建循环（增加探索性）
	var extra_corridors = randi() % 3  # 0-2个额外走廊
	for i in range(extra_corridors):
		var room1 = randi() % rooms.size()
		var room2 = randi() % rooms.size()
		
		# 确保选择不同的房间
		if room1 != room2:
			_create_corridor(room_rects[room1], room_rects[room2], room1, room2, biome_type)

# 创建走廊
func _create_corridor(rect1, rect2, room1_index, room2_index, biome_type):
	# 计算两个房间的中心点
	var center1 = rect1.position + rect1.size / 2
	var center2 = rect2.position + rect2.size / 2
	
	# 确定走廊宽度
	var corridor_width = min_corridor_width + randi() % int(max_corridor_width - min_corridor_width)
	
	# 创建L形走廊（水平然后垂直）
	var horizontal_corridor
	var vertical_corridor
	
	# 水平走廊
	var h_rect
	if center1.x < center2.x:
		h_rect = Rect2(center1.x, center1.y - corridor_width / 2, center2.x - center1.x, corridor_width)
	else:
		h_rect = Rect2(center2.x, center1.y - corridor_width / 2, center1.x - center2.x, corridor_width)
	
	horizontal_corridor = _create_room(h_rect, RoomType.CORRIDOR, biome_type)
	horizontal_corridor.set_meta("start_room", room1_index)
	horizontal_corridor.set_meta("end_room", room2_index)
	
	# 垂直走廊
	var v_rect
	if center1.y < center2.y:
		v_rect = Rect2(center2.x - corridor_width / 2, center1.y, corridor_width, center2.y - center1.y)
	else:
		v_rect = Rect2(center2.x - corridor_width / 2, center2.y, corridor_width, center1.y - center2.y)
	
	vertical_corridor = _create_room(v_rect, RoomType.CORRIDOR, biome_type)
	vertical_corridor.set_meta("start_room", room1_index)
	vertical_corridor.set_meta("end_room", room2_index)
	
	# 将走廊添加到走廊组
	horizontal_corridor.add_to_group("corridors")
	vertical_corridor.add_to_group("corridors")

# 在房间内放置平台、金币和敌人
func _populate_rooms(rooms, room_rects, biome_type):
	for i in range(rooms.size()):
		var room = rooms[i]
		var rect = room_rects[i]
		var room_type = room.get_meta("type")
		
		# 使用配置系统获取平台数量
		var platform_count = room_config.get_platform_count(room_type, biome_type)
		
		# 如果是氧气室，放置氧气发生器
		if room_config.should_place_oxygen_generator(room_type, biome_type):
			var generator_pos = Vector2(
				rect.position.x + rect.size.x / 2,
				rect.position.y + rect.size.y / 2
			)
			_create_oxygen_generator(generator_pos, biome_type)
		
		# 在房间内放置平台
		for j in range(platform_count):
			# 计算平台位置
			var platform_x = rect.position.x + randf_range(50, rect.size.x - 50)
			var platform_y = rect.position.y + randf_range(50, rect.size.y - 50)
			var platform_pos = Vector2(platform_x, platform_y)
			
			# 使用配置系统决定是否为移动平台
			var is_moving = room_config.should_use_moving_platform(room_type, biome_type)
			
			# 创建平台
			var platform_scale = Vector2(1.0 + randf() * 0.5, 0.5 + randf() * 0.2)
			var platform = _create_platform(platform_pos, platform_scale, biome_type, is_moving)
			
			# 使用配置系统决定是否放置金币
			if room_config.should_place_coin(room_type, biome_type):
				var coin_pos = Vector2(platform_pos.x, platform_pos.y - 30)
				_create_coin(coin_pos, 1, biome_type)
			
			# 使用配置系统决定是否放置史莱姆
			if room_config.should_place_enemy(room_type, biome_type):
				var slime_pos = Vector2(platform_pos.x, platform_pos.y - 20)
				
				# 使用配置系统决定是否使用紫色史莱姆
				var is_purple = room_config.should_use_purple_slime(room_type, biome_type)
				var slime_type = 1 if is_purple else 0  # 1=紫色, 0=绿色
				
				_create_slime(slime_pos, slime_type, biome_type, Vector2(1.0, 1.0))

# 从随机关卡生成器中实现的函数

func _create_platform(position, scale, biome_type, is_moving):
	# 创建平台
	var platform = preload("res://scenes/platform.tscn").instantiate()
	platform.position = position
	platform.scale = scale
	
	# 根据生物群系设置平台颜色
	var sprite = platform.get_node("Sprite2D")
	if biome_type == "FOREST":
		sprite.modulate = Color(0.2, 0.8, 0.2)  # 绿色平台
	elif biome_type == "CAVE":
		sprite.modulate = Color(0.6, 0.6, 0.6)  # 灰色平台
	elif biome_type == "SWAMP":
		sprite.modulate = Color(0.5, 0.4, 0.1)  # 棕色平台
	
	# 设置是否为移动平台
	if is_moving:
		platform.is_moving = true
		platform.move_speed = 50  # 默认移动速度
		platform.move_distance = 100  # 默认移动距离
	
	# 添加到场景
	if not has_node("Platforms"):
		var platforms = Node2D.new()
		platforms.name = "Platforms"
		add_child(platforms)
	
	$Platforms.add_child(platform)
	return platform

func _create_coin(position, value, biome_type):
	# 创建金币
	var coin = preload("res://scenes/coin.tscn").instantiate()
	coin.position = position
	
	# 添加到场景
	if not has_node("Coins"):
		var coins = Node2D.new()
		coins.name = "Coins"
		add_child(coins)
	
	$Coins.add_child(coin)
	return coin

func _create_slime(position, slime_type, biome_type, scale):
	# 创建史莱姆敌人
	var slime = preload("res://scenes/slime.tscn").instantiate()
	slime.position = position
	slime.scale = scale
	
	# 如果是紫色史莱姆，修改精灵图像和速度
	if slime_type == 1:  # 1=紫色, 0=绿色
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

func _create_oxygen_generator(position, biome_type):
	# 创建氧气发生器节点
	var generator = Sprite2D.new()
	generator.position = position
	generator.name = "OxygenGenerator"
	
	# 设置纹理（使用金币纹理作为临时替代）
	var texture = load("res://assets/sprites/coin.png")
	generator.texture = texture
	
	# 根据生物群系设置颜色
	if biome_type == "FOREST":
		generator.modulate = Color(0.3, 0.9, 1.0)  # 蓝色
	elif biome_type == "CAVE":
		generator.modulate = Color(0.5, 0.8, 1.0)  # 淡蓝色
	elif biome_type == "SWAMP":
		generator.modulate = Color(0.2, 0.6, 0.8)  # 深蓝色
	
	# 设置缩放
	generator.scale = Vector2(0.8, 0.8)
	
	# 添加到场景
	if not has_node("OxygenGenerators"):
		var generators = Node2D.new()
		generators.name = "OxygenGenerators"
		add_child(generators)
	
	$OxygenGenerators.add_child(generator)
	
	# 添加发光效果
	var light = PointLight2D.new()
	light.texture = texture
	light.color = Color(0.3, 0.7, 1.0, 0.5)  # 蓝色半透明
	light.energy = 0.8
	light.texture_scale = 3.0
	generator.add_child(light)
	
	# 添加动画
	var anim_player = AnimationPlayer.new()
	generator.add_child(anim_player)
	
	# 创建脉动动画
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, ":scale")
	animation.track_insert_key(track_index, 0.0, Vector2(0.8, 0.8))
	animation.track_insert_key(track_index, 1.0, Vector2(1.0, 1.0))
	animation.set_length(2.0)
	animation.set_loop_mode(Animation.LOOP_PINGPONG)
	
	# 将动画添加到播放器
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("pulse", animation)
	anim_player.add_animation_library("default", anim_lib)
	anim_player.play("default/pulse")
	
	return generator