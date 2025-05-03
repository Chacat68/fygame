extends Node

# 程序化地形生成和房间系统
# 用于在随机关卡生成器中实现《缺氧》风格的房间和走廊系统

# 房间类型
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
	# 创建房间节点
	var room = ColorRect.new()
	room.name = "Room_" + str(room_type)
	room.position = rect.position
	room.size = rect.size
	
	# 根据房间类型设置颜色
	var room_color
	if room_type == RoomType.ENTRANCE:
		room_color = Color(0.2, 0.7, 0.3, 0.3)  # 绿色半透明
	elif room_type == RoomType.CORRIDOR:
		room_color = Color(0.5, 0.5, 0.5, 0.3)  # 灰色半透明
	elif room_type == RoomType.STORAGE:
		room_color = Color(0.7, 0.7, 0.2, 0.3)  # 黄色半透明
	elif room_type == RoomType.OXYGEN:
		room_color = Color(0.2, 0.6, 0.8, 0.3)  # 蓝色半透明
	elif room_type == RoomType.CHALLENGE:
		room_color = Color(0.8, 0.3, 0.3, 0.3)  # 红色半透明
	elif room_type == RoomType.TREASURE:
		room_color = Color(0.8, 0.6, 0.2, 0.3)  # 金色半透明
	
	# 根据生物群系调整颜色
	if biome_type == "CAVE":
		room_color = room_color.darkened(0.2)
	elif biome_type == "SWAMP":
		room_color = room_color.blend(Color(0.3, 0.3, 0.1, 0.3))
	
	room.color = room_color
	
	# 设置元数据
	room.set_meta("type", room_type)
	room.set_meta("rect", rect)
	
	# 添加到房间组
	room.add_to_group("rooms")
	
	# 添加到场景
	$Rooms.add_child(room)
	
	# 添加房间标签
	var label = Label.new()
	var room_name = ""
	if room_type == RoomType.ENTRANCE:
		room_name = "入口"
	elif room_type == RoomType.CORRIDOR:
		room_name = "走廊"
	elif room_type == RoomType.STORAGE:
		room_name = "储藏室"
	elif room_type == RoomType.OXYGEN:
		room_name = "氧气室"
	elif room_type == RoomType.CHALLENGE:
		room_name = "挑战室"
	elif room_type == RoomType.TREASURE:
		room_name = "宝藏室"
	
	label.text = room_name
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
		
		# 根据房间类型决定平台数量
		var platform_count = 0
		var coin_chance = 0.0
		var slime_chance = 0.0
		
		if room_type == RoomType.ENTRANCE:
			platform_count = 3 + randi() % 3  # 3-5个平台
			coin_chance = 0.3
			slime_chance = 0.1
		elif room_type == RoomType.CORRIDOR:
			platform_count = 2 + randi() % 2  # 2-3个平台
			coin_chance = 0.2
			slime_chance = 0.1
		elif room_type == RoomType.STORAGE:
			platform_count = 4 + randi() % 3  # 4-6个平台
			coin_chance = 0.7  # 更多金币
			slime_chance = 0.2
		elif room_type == RoomType.OXYGEN:
			platform_count = 3 + randi() % 3  # 3-5个平台
			coin_chance = 0.3
			slime_chance = 0.1
			# 在氧气室放置额外的氧气发生器
			var generator_pos = Vector2(
				rect.position.x + rect.size.x / 2,
				rect.position.y + rect.size.y / 2
			)
			_create_oxygen_generator(generator_pos, biome_type)
		elif room_type == RoomType.CHALLENGE:
			platform_count = 5 + randi() % 3  # 5-7个平台
			coin_chance = 0.4
			slime_chance = 0.6  # 更多敌人
		elif room_type == RoomType.TREASURE:
			platform_count = 3 + randi() % 2  # 3-4个平台
			coin_chance = 0.9  # 大量金币
			slime_chance = 0.3
		
		# 在房间内放置平台
		for j in range(platform_count):
			# 计算平台位置
			var platform_x = rect.position.x + randf_range(50, rect.size.x - 50)
			var platform_y = rect.position.y + randf_range(50, rect.size.y - 50)
			var platform_pos = Vector2(platform_x, platform_y)
			
			# 创建平台
			var is_moving = false
			if room_type == RoomType.CHALLENGE:
				is_moving = randf() < 0.4  # 挑战室中40%的平台是移动的
			elif room_type == RoomType.CORRIDOR:
				is_moving = randf() < 0.3  # 走廊中30%的平台是移动的
			else:
				is_moving = randf() < 0.2  # 其他房间20%的平台是移动的
			
			var platform_scale = Vector2(1.0 + randf() * 0.5, 0.5 + randf() * 0.2)
			var platform = _create_platform(platform_pos, platform_scale, biome_type, is_moving)
			
			# 在平台上放置金币
			if randf() < coin_chance:
				var coin_pos = Vector2(platform_pos.x, platform_pos.y - 30)
				_create_coin(coin_pos, 1, biome_type)
			
			# 在平台上放置史莱姆
			if randf() < slime_chance:
				var slime_pos = Vector2(platform_pos.x, platform_pos.y - 20)
				var slime_type = 0  # 绿色史莱姆
				
				# 在挑战室和沼泽生物群系中增加紫色史莱姆的概率
				if room_type == RoomType.CHALLENGE or biome_type == "SWAMP":
					if randf() < 0.6:
						slime_type = 1  # 紫色史莱姆
				
				_create_slime(slime_pos, slime_type, biome_type, Vector2(1.0, 1.0))

# 这些函数需要在随机关卡生成器中实现
# 以下是函数签名，实际实现应该使用现有的函数

# func _create_platform(position, scale, biome_type, is_moving):
#     # 实现平台创建逻辑
#     pass

# func _create_coin(position, value, biome_type):
#     # 实现金币创建逻辑
#     pass

# func _create_slime(position, slime_type, biome_type, scale):
#     # 实现史莱姆创建逻辑
#     pass

# func _create_oxygen_generator(position, biome_type):
#     # 实现氧气发生器创建逻辑
#     pass