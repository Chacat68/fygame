extends Node

# 程序化地形生成和房间系统
# 用于在随机关卡生成器中实现《缺氧》风格的房间和走廊系统

# 预加载房间配置资源
var room_config = preload("res://scripts/room_config.gd").new()

# 房间类型枚举 - 从配置文件中导入以保持一致性
enum RoomType {
	ENTRANCE = 0,    # 入口房间
	CORRIDOR = 1,    # 走廊
	LIVING = 2,      # 生活区
	FARM = 3,        # 农场
	POWER = 4,       # 发电站
	RESEARCH = 5,    # 研究站
	STORAGE = 6,     # 储藏室
	MEDICAL = 7,     # 医疗站
	INDUSTRIAL = 8,  # 工业区
	RECREATION = 9,  # 娱乐区
	WATER = 10,      # 水处理
	OXYGEN = 11      # 制氧站
}

# 房间参数
var grid_size = 32  # 每个格子的像素大小
var min_room_size = Vector2(4, 4)  # 最小房间大小（格子数）
var max_room_size = Vector2(8, 8)  # 最大房间大小（格子数）
var min_corridor_width = 2  # 最小走廊宽度（格子数）
var max_corridor_width = 3  # 最大走廊宽度（格子数）
var room_spacing = 2  # 房间间距（格子数）

# 房间布局参数
var level_width = 50  # 关卡宽度（格子数）
var level_height = 30  # 关卡高度（格子数）
var max_rooms = 15  # 最大房间数
var min_rooms = 10  # 最小房间数

# 房间布局模式
enum LayoutMode {
	LINEAR = 0,    # 线性布局
	BRANCHING = 1, # 分支布局
	MAZE = 2,      # 迷宫布局
	OPEN = 3       # 开放布局
}

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
	
	# 选择布局模式
	var layout_mode = _select_layout_mode(biome_type)
	
	# 生成房间
	var rooms = []
	var room_rects = []
	
	# 根据布局模式生成房间
	match layout_mode:
		LayoutMode.LINEAR:
			_generate_linear_layout(rooms, room_rects, room_count, biome_type)
		LayoutMode.BRANCHING:
			_generate_branching_layout(rooms, room_rects, room_count, biome_type)
		LayoutMode.MAZE:
			_generate_maze_layout(rooms, room_rects, room_count, biome_type)
		LayoutMode.OPEN:
			_generate_open_layout(rooms, room_rects, room_count, biome_type)
	
	# 连接房间
	_connect_rooms(rooms, room_rects, layout_mode, biome_type)
	
	# 填充房间内容
	_populate_rooms(rooms, room_rects, biome_type)

# 选择布局模式
func _select_layout_mode(biome_type):
	# 根据生物群系和关卡难度选择布局模式
	var mode_roll = randf()
	
	match biome_type:
		"FOREST":
			# 森林倾向于分支布局
			if mode_roll < 0.4:
				return LayoutMode.BRANCHING
			elif mode_roll < 0.7:
				return LayoutMode.LINEAR
			else:
				return LayoutMode.OPEN
		"CAVE":
			# 洞穴倾向于迷宫布局
			if mode_roll < 0.5:
				return LayoutMode.MAZE
			elif mode_roll < 0.8:
				return LayoutMode.BRANCHING
			else:
				return LayoutMode.LINEAR
		"SWAMP":
			# 沼泽倾向于开放布局
			if mode_roll < 0.4:
				return LayoutMode.OPEN
			elif mode_roll < 0.7:
				return LayoutMode.BRANCHING
			else:
				return LayoutMode.MAZE
		_:
			return LayoutMode.LINEAR

# 生成线性布局
func _generate_linear_layout(rooms, room_rects, room_count, biome_type):
	# 创建入口房间（左侧）
	var entrance_room = _create_room(
		Rect2(2, level_height/2 - 2, 4, 4),
		RoomType.ENTRANCE,
		biome_type
	)
	rooms.append(entrance_room)
	room_rects.append(Rect2(2, level_height/2 - 2, 4, 4))
	
	# 创建中间房间
	var current_x = 8
	for i in range(room_count - 2):
		var room_width = min_room_size.x + randi() % int(max_room_size.x - min_room_size.x)
		var room_height = min_room_size.y + randi() % int(max_room_size.y - min_room_size.y)
		var room_y = 2 + randi() % int(level_height - room_height - 4)
		
		var room_type = _select_room_type(i, room_count - 2)
		var room = _create_room(
			Rect2(current_x, room_y, room_width, room_height),
			room_type,
			biome_type
		)
		rooms.append(room)
		room_rects.append(Rect2(current_x, room_y, room_width, room_height))
		
		current_x += room_width + room_spacing
	
	# 创建制氧站（右侧）
	var oxygen_room = _create_room(
		Rect2(level_width - 6, level_height/2 - 2, 4, 4),
		RoomType.OXYGEN,
		biome_type
	)
	rooms.append(oxygen_room)
	room_rects.append(Rect2(level_width - 6, level_height/2 - 2, 4, 4))

# 生成分支布局
func _generate_branching_layout(rooms, room_rects, room_count, biome_type):
	# 创建入口房间（左侧）
	var entrance_room = _create_room(
		Rect2(2, level_height/2 - 2, 4, 4),
		RoomType.ENTRANCE,
		biome_type
	)
	rooms.append(entrance_room)
	room_rects.append(Rect2(2, level_height/2 - 2, 4, 4))
	
	# 创建分支房间
	var main_path_rooms = []
	var branch_rooms = []
	
	# 生成主路径房间
	var current_x = 8
	for i in range(room_count / 2):
		var room_width = min_room_size.x + randi() % int(max_room_size.x - min_room_size.x)
		var room_height = min_room_size.y + randi() % int(max_room_size.y - min_room_size.y)
		var room_y = 2 + randi() % int(level_height - room_height - 4)
		
		var room_type = _select_room_type(i, room_count / 2)
		var room = _create_room(
			Rect2(current_x, room_y, room_width, room_height),
			room_type,
			biome_type
		)
		main_path_rooms.append(room)
		room_rects.append(Rect2(current_x, room_y, room_width, room_height))
		
		current_x += room_width + room_spacing
	
	# 生成分支房间
	for i in range(room_count / 2):
		var parent_room = main_path_rooms[randi() % main_path_rooms.size()]
		var parent_rect = room_rects[rooms.find(parent_room)]
		
		var room_width = min_room_size.x + randi() % int(max_room_size.x - min_room_size.x)
		var room_height = min_room_size.y + randi() % int(max_room_size.y - min_room_size.y)
		
		# 随机选择分支方向（上、下、左、右）
		var direction = randi() % 4
		var room_x = parent_rect.position.x
		var room_y = parent_rect.position.y
		
		match direction:
			0: # 上
				room_y = parent_rect.position.y - room_height - room_spacing
			1: # 下
				room_y = parent_rect.position.y + parent_rect.size.y + room_spacing
			2: # 左
				room_x = parent_rect.position.x - room_width - room_spacing
			3: # 右
				room_x = parent_rect.position.x + parent_rect.size.x + room_spacing
		
		var room_type = _select_room_type(i, room_count / 2, true)
		var room = _create_room(
			Rect2(room_x, room_y, room_width, room_height),
			room_type,
			biome_type
		)
		branch_rooms.append(room)
		room_rects.append(Rect2(room_x, room_y, room_width, room_height))
	
	# 合并房间列表
	rooms.append_array(main_path_rooms)
	rooms.append_array(branch_rooms)
	
	# 创建制氧站（右侧）
	var oxygen_room = _create_room(
		Rect2(level_width - 6, level_height/2 - 2, 4, 4),
		RoomType.OXYGEN,
		biome_type
	)
	rooms.append(oxygen_room)
	room_rects.append(Rect2(level_width - 6, level_height/2 - 2, 4, 4))

# 生成迷宫布局
func _generate_maze_layout(rooms, room_rects, room_count, biome_type):
	# 创建入口房间（左侧）
	var entrance_room = _create_room(
		Rect2(2, level_height/2 - 2, 4, 4),
		RoomType.ENTRANCE,
		biome_type
	)
	rooms.append(entrance_room)
	room_rects.append(Rect2(2, level_height/2 - 2, 4, 4))
	
	# 创建迷宫房间
	var grid_size = ceil(sqrt(room_count - 2))
	var cell_width = (level_width - 8) / grid_size
	var cell_height = (level_height - 4) / grid_size
	
	for y in range(grid_size):
		for x in range(grid_size):
			if rooms.size() >= room_count - 1:
				break
			
			var room_width = cell_width * 0.8
			var room_height = cell_height * 0.8
			var room_x = 4 + x * cell_width + (cell_width - room_width) / 2
			var room_y = 2 + y * cell_height + (cell_height - room_height) / 2
			
			var room_type = _select_room_type(rooms.size() - 1, room_count - 2)
			var room = _create_room(
				Rect2(room_x, room_y, room_width, room_height),
				room_type,
				biome_type
			)
			rooms.append(room)
			room_rects.append(Rect2(room_x, room_y, room_width, room_height))
	
	# 创建制氧站（右侧）
	var oxygen_room = _create_room(
		Rect2(level_width - 6, level_height/2 - 2, 4, 4),
		RoomType.OXYGEN,
		biome_type
	)
	rooms.append(oxygen_room)
	room_rects.append(Rect2(level_width - 6, level_height/2 - 2, 4, 4))

# 生成开放布局
func _generate_open_layout(rooms, room_rects, room_count, biome_type):
	# 创建入口房间（左侧）
	var entrance_room = _create_room(
		Rect2(2, level_height/2 - 2, 4, 4),
		RoomType.ENTRANCE,
		biome_type
	)
	rooms.append(entrance_room)
	room_rects.append(Rect2(2, level_height/2 - 2, 4, 4))
	
	# 创建开放区域房间
	var center_x = level_width / 2
	var center_y = level_height / 2
	var radius = min(level_width, level_height) / 3
	
	for i in range(room_count - 2):
		var angle = randf() * PI * 2
		var distance = randf() * radius
		var room_width = min_room_size.x + randi() % int(max_room_size.x - min_room_size.x)
		var room_height = min_room_size.y + randi() % int(max_room_size.y - min_room_size.y)
		
		var room_x = center_x + cos(angle) * distance - room_width / 2
		var room_y = center_y + sin(angle) * distance - room_height / 2
		
		var room_type = _select_room_type(i, room_count - 2)
		var room = _create_room(
			Rect2(room_x, room_y, room_width, room_height),
			room_type,
			biome_type
		)
		rooms.append(room)
		room_rects.append(Rect2(room_x, room_y, room_width, room_height))
	
	# 创建制氧站（右侧）
	var oxygen_room = _create_room(
		Rect2(level_width - 6, level_height/2 - 2, 4, 4),
		RoomType.OXYGEN,
		biome_type
	)
	rooms.append(oxygen_room)
	room_rects.append(Rect2(level_width - 6, level_height/2 - 2, 4, 4))

# 选择房间类型
func _select_room_type(index, total_rooms, is_branch = false):
	var type_roll = randf()
	
	if is_branch:
		# 分支房间更可能是特殊房间
		if type_roll < 0.2:
			return RoomType.FARM
		elif type_roll < 0.4:
			return RoomType.POWER
		elif type_roll < 0.6:
			return RoomType.STORAGE
		elif type_roll < 0.8:
			return RoomType.RECREATION
		else:
			return RoomType.CORRIDOR
	else:
		# 主路径房间
		if index == 0:
			return RoomType.ENTRANCE
		elif index == total_rooms - 1:
			return RoomType.OXYGEN
		else:
			if type_roll < 0.2:
				return RoomType.LIVING
			elif type_roll < 0.4:
				return RoomType.RESEARCH
			elif type_roll < 0.6:
				return RoomType.MEDICAL
			elif type_roll < 0.8:
				return RoomType.WATER
			else:
				return RoomType.INDUSTRIAL

# 连接房间
func _connect_rooms(rooms, room_rects, layout_mode, biome_type):
	match layout_mode:
		LayoutMode.LINEAR:
			_connect_linear_rooms(rooms, room_rects, biome_type)
		LayoutMode.BRANCHING:
			_connect_branching_rooms(rooms, room_rects, biome_type)
		LayoutMode.MAZE:
			_connect_maze_rooms(rooms, room_rects, biome_type)
		LayoutMode.OPEN:
			_connect_open_rooms(rooms, room_rects, biome_type)

# 连接线性布局的房间
func _connect_linear_rooms(rooms, room_rects, biome_type):
	for i in range(rooms.size() - 1):
		_create_corridor(room_rects[i], room_rects[i + 1], biome_type)

# 连接分支布局的房间
func _connect_branching_rooms(rooms, room_rects, biome_type):
	# 连接主路径房间
	for i in range(rooms.size() - 1):
		if _should_connect_rooms(rooms[i], rooms[i + 1]):
			_create_corridor(room_rects[i], room_rects[i + 1], biome_type)
	
	# 连接分支房间
	for i in range(rooms.size()):
		for j in range(i + 1, rooms.size()):
			if _should_connect_rooms(rooms[i], rooms[j]):
				_create_corridor(room_rects[i], room_rects[j], biome_type)

# 连接迷宫布局的房间
func _connect_maze_rooms(rooms, room_rects, biome_type):
	# 使用Prim算法生成最小生成树
	var connected = [0]  # 从入口房间开始
	var unconnected = range(1, rooms.size())
	
	while unconnected.size() > 0:
		var min_dist = INF
		var connect_from = -1
		var connect_to = -1
		
		for i in connected:
			for j in unconnected:
				var dist = room_rects[i].position.distance_to(room_rects[j].position)
				if dist < min_dist:
					min_dist = dist
					connect_from = i
					connect_to = j
		
		if connect_from != -1 and connect_to != -1:
			_create_corridor(room_rects[connect_from], room_rects[connect_to], biome_type)
			connected.append(connect_to)
			unconnected.erase(connect_to)
	
	# 添加一些额外的随机连接
	for i in range(rooms.size() / 4):
		var from_idx = randi() % rooms.size()
		var to_idx = randi() % rooms.size()
		if from_idx != to_idx:
			_create_corridor(room_rects[from_idx], room_rects[to_idx], biome_type)

# 连接开放布局的房间
func _connect_open_rooms(rooms, room_rects, biome_type):
	# 连接所有相邻的房间
	for i in range(rooms.size()):
		for j in range(i + 1, rooms.size()):
			var dist = room_rects[i].position.distance_to(room_rects[j].position)
			if dist < max_room_size.x * 1.5:
				_create_corridor(room_rects[i], room_rects[j], biome_type)

# 判断是否应该连接两个房间
func _should_connect_rooms(room1, room2):
	var type1 = room1.get_meta("type")
	var type2 = room2.get_meta("type")
	
	# 入口房间和制氧站必须连接
	if type1 == RoomType.ENTRANCE or type2 == RoomType.ENTRANCE:
		return true
	if type1 == RoomType.OXYGEN or type2 == RoomType.OXYGEN:
		return true
	
	# 特殊房间的连接规则
	if type1 == RoomType.POWER or type2 == RoomType.POWER:
		return randf() < 0.8  # 80%概率连接发电站
	if type1 == RoomType.WATER or type2 == RoomType.WATER:
		return randf() < 0.7  # 70%概率连接水处理
	
	# 其他房间的连接规则
	return randf() < 0.6  # 60%概率连接其他房间

# 创建走廊
func _create_corridor(rect1, rect2, biome_type):
	var corridor_width = min_corridor_width + randi() % int(max_corridor_width - min_corridor_width)
	
	# 计算走廊位置和方向
	var start_pos = rect1.position + rect1.size / 2
	var end_pos = rect2.position + rect2.size / 2
	var direction = (end_pos - start_pos).normalized()
	
	# 创建走廊
	var corridor = ColorRect.new()
	corridor.position = start_pos
	corridor.size = Vector2(
		start_pos.distance_to(end_pos),
		corridor_width * grid_size
	)
	corridor.color = Color(0.3, 0.3, 0.3, 0.5)
	corridor.rotation = direction.angle()
	
	# 添加到走廊容器
	$Corridors.add_child(corridor)
	
	# 在走廊中放置管道
	_place_pipes_in_corridor(corridor, biome_type)

# 在走廊中放置管道
func _place_pipes_in_corridor(corridor, biome_type):
	var pipe_spacing = 4 * grid_size  # 每4格放置一个管道
	
	for i in range(corridor.size.x / pipe_spacing):
		var pipe_pos = Vector2(
			corridor.position.x + i * pipe_spacing,
			corridor.position.y
		)
		
		_create_pipe(pipe_pos, biome_type)

# 填充房间内容
func _populate_rooms(rooms, room_rects, biome_type):
	for i in range(rooms.size()):
		var room = rooms[i]
		var rect = room_rects[i]
		var room_type = room.get_meta("type")
		
		# 根据房间类型放置特殊物品
		match room_type:
			RoomType.LIVING:
				_create_living_room_items(rect, biome_type)
			RoomType.FARM:
				_create_farm_items(rect, biome_type)
			RoomType.POWER:
				_create_power_items(rect, biome_type)
			RoomType.RESEARCH:
				_create_research_items(rect, biome_type)
			RoomType.MEDICAL:
				_create_medical_items(rect, biome_type)
			RoomType.INDUSTRIAL:
				_create_industrial_items(rect, biome_type)
			RoomType.RECREATION:
				_create_recreation_items(rect, biome_type)
			RoomType.WATER:
				_create_water_items(rect, biome_type)
			RoomType.OXYGEN:
				_create_oxygen_items(rect, biome_type)

# 创建生活区物品
func _create_living_room_items(rect, biome_type):
	# 创建床铺
	for i in range(2):
		var bed_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 2
		)
		_create_bed(bed_pos, biome_type)
	
	# 创建餐桌
	var table_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 4
	)
	_create_table(table_pos, biome_type)

# 创建农场物品
func _create_farm_items(rect, biome_type):
	# 创建种植区
	for i in range(4):
		for j in range(2):
			var plot_pos = Vector2(
				rect.position.x + (i + 1) * rect.size.x / 5,
				rect.position.y + (j + 1) * rect.size.y / 3
			)
			_create_farm_plot(plot_pos, biome_type)
	
	# 创建灌溉系统
	var irrigation_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y - grid_size
	)
	_create_irrigation_system(irrigation_pos, biome_type)

# 创建发电站物品
func _create_power_items(rect, biome_type):
	# 创建发电机
	var generator_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
	_create_generator(generator_pos, biome_type)
	
	# 创建电池组
	for i in range(2):
		var battery_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 4
		)
		_create_battery(battery_pos, biome_type)

# 创建研究站物品
func _create_research_items(rect, biome_type):
	# 创建研究台
	var research_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
	_create_research_station(research_pos, biome_type)
	
	# 创建书架
	for i in range(2):
		var shelf_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 4
		)
		_create_bookshelf(shelf_pos, biome_type)

# 创建医疗站物品
func _create_medical_items(rect, biome_type):
	# 创建医疗床
	var bed_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
	_create_medical_bed(bed_pos, biome_type)
	
	# 创建医疗设备
	for i in range(2):
		var device_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 4
		)
		_create_medical_device(device_pos, biome_type)

# 创建工业区物品
func _create_industrial_items(rect, biome_type):
	# 创建工作台
	for i in range(2):
		var workbench_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 2
		)
		_create_workbench(workbench_pos, biome_type)
	
	# 创建储物柜
	var storage_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 4
	)
	_create_storage_cabinet(storage_pos, biome_type)

# 创建娱乐区物品
func _create_recreation_items(rect, biome_type):
	# 创建娱乐设施
	for i in range(2):
		var recreation_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 2
		)
		_create_recreation_facility(recreation_pos, biome_type)
	
	# 创建休息区
	var rest_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 4
	)
	_create_rest_area(rest_pos, biome_type)

# 创建水处理物品
func _create_water_items(rect, biome_type):
	# 创建水处理器
	var processor_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
	_create_water_processor(processor_pos, biome_type)
	
	# 创建储水罐
	for i in range(2):
		var tank_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 4
		)
		_create_water_tank(tank_pos, biome_type)

# 创建制氧站物品
func _create_oxygen_items(rect, biome_type):
	# 创建制氧机
	var generator_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
	_create_oxygen_generator(generator_pos, biome_type)
	
	# 创建氧气罐
	for i in range(2):
		var tank_pos = Vector2(
			rect.position.x + (i + 1) * rect.size.x / 3,
			rect.position.y + rect.size.y / 4
		)
		_create_oxygen_tank(tank_pos, biome_type)

# 创建单个房间
func _create_room(rect, room_type, biome_type):
	# 获取房间配置
	var config = room_config.get_room_config(room_type, biome_type)
	
	# 创建房间节点
	var room = ColorRect.new()
	room.name = "Room_" + str(room_type)
	room.position = rect.position * grid_size
	room.size = rect.size * grid_size
	
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
	label.position = Vector2(rect.size.x * grid_size / 2 - 20, rect.size.y * grid_size / 2 - 10)
	room.add_child(label)
	
	return room

# 创建各种设施的函数
func _create_bed(pos, biome_type):
	var bed = ColorRect.new()
	bed.position = pos * grid_size
	bed.size = Vector2(2, 1) * grid_size
	bed.color = Color(0.8, 0.6, 0.4, 0.8)
	$Rooms.add_child(bed)

func _create_table(pos, biome_type):
	var table = ColorRect.new()
	table.position = pos * grid_size
	table.size = Vector2(3, 2) * grid_size
	table.color = Color(0.6, 0.4, 0.2, 0.8)
	$Rooms.add_child(table)

func _create_farm_plot(pos, biome_type):
	var plot = ColorRect.new()
	plot.position = pos * grid_size
	plot.size = Vector2(2, 2) * grid_size
	plot.color = Color(0.4, 0.6, 0.2, 0.8)
	$Rooms.add_child(plot)

func _create_irrigation_system(pos, biome_type):
	var system = ColorRect.new()
	system.position = pos * grid_size
	system.size = Vector2(4, 1) * grid_size
	system.color = Color(0.2, 0.4, 0.8, 0.8)
	$Rooms.add_child(system)

func _create_generator(pos, biome_type):
	var generator = ColorRect.new()
	generator.position = pos * grid_size
	generator.size = Vector2(3, 3) * grid_size
	generator.color = Color(0.8, 0.2, 0.2, 0.8)
	$Rooms.add_child(generator)

func _create_battery(pos, biome_type):
	var battery = ColorRect.new()
	battery.position = pos * grid_size
	battery.size = Vector2(2, 2) * grid_size
	battery.color = Color(0.8, 0.8, 0.2, 0.8)
	$Rooms.add_child(battery)

func _create_research_station(pos, biome_type):
	var station = ColorRect.new()
	station.position = pos * grid_size
	station.size = Vector2(3, 2) * grid_size
	station.color = Color(0.6, 0.2, 0.8, 0.8)
	$Rooms.add_child(station)

func _create_bookshelf(pos, biome_type):
	var shelf = ColorRect.new()
	shelf.position = pos * grid_size
	shelf.size = Vector2(2, 3) * grid_size
	shelf.color = Color(0.4, 0.2, 0.0, 0.8)
	$Rooms.add_child(shelf)

func _create_medical_bed(pos, biome_type):
	var bed = ColorRect.new()
	bed.position = pos * grid_size
	bed.size = Vector2(2, 1) * grid_size
	bed.color = Color(1.0, 0.8, 0.8, 0.8)
	$Rooms.add_child(bed)

func _create_medical_device(pos, biome_type):
	var device = ColorRect.new()
	device.position = pos * grid_size
	device.size = Vector2(2, 2) * grid_size
	device.color = Color(0.8, 0.8, 1.0, 0.8)
	$Rooms.add_child(device)

func _create_workbench(pos, biome_type):
	var bench = ColorRect.new()
	bench.position = pos * grid_size
	bench.size = Vector2(3, 2) * grid_size
	bench.color = Color(0.4, 0.4, 0.4, 0.8)
	$Rooms.add_child(bench)

func _create_storage_cabinet(pos, biome_type):
	var cabinet = ColorRect.new()
	cabinet.position = pos * grid_size
	cabinet.size = Vector2(2, 3) * grid_size
	cabinet.color = Color(0.5, 0.3, 0.0, 0.8)
	$Rooms.add_child(cabinet)

func _create_recreation_facility(pos, biome_type):
	var facility = ColorRect.new()
	facility.position = pos * grid_size
	facility.size = Vector2(2, 2) * grid_size
	facility.color = Color(0.8, 0.8, 0.2, 0.8)
	$Rooms.add_child(facility)

func _create_rest_area(pos, biome_type):
	var area = ColorRect.new()
	area.position = pos * grid_size
	area.size = Vector2(3, 2) * grid_size
	area.color = Color(0.6, 0.8, 0.8, 0.8)
	$Rooms.add_child(area)

func _create_water_processor(pos, biome_type):
	var processor = ColorRect.new()
	processor.position = pos * grid_size
	processor.size = Vector2(3, 3) * grid_size
	processor.color = Color(0.2, 0.4, 0.8, 0.8)
	$Rooms.add_child(processor)

func _create_water_tank(pos, biome_type):
	var tank = ColorRect.new()
	tank.position = pos * grid_size
	tank.size = Vector2(2, 3) * grid_size
	tank.color = Color(0.2, 0.6, 1.0, 0.8)
	$Rooms.add_child(tank)

func _create_oxygen_generator(pos, biome_type):
	var generator = ColorRect.new()
	generator.position = pos * grid_size
	generator.size = Vector2(3, 3) * grid_size
	generator.color = Color(0.2, 0.8, 0.8, 0.8)
	$Rooms.add_child(generator)

func _create_oxygen_tank(pos, biome_type):
	var tank = ColorRect.new()
	tank.position = pos * grid_size
	tank.size = Vector2(2, 3) * grid_size
	tank.color = Color(0.4, 0.8, 1.0, 0.8)
	$Rooms.add_child(tank)

func _create_pipe(pos, biome_type):
	var pipe = ColorRect.new()
	pipe.position = pos * grid_size
	pipe.size = Vector2(1, 1) * grid_size
	pipe.color = Color(0.6, 0.6, 0.6, 0.8)
	$Corridors.add_child(pipe)