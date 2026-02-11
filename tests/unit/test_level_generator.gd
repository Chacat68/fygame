extends GutTest

# LevelGenerator 单元测试
# 测试数据驱动的关卡生成系统

var level_generator: LevelGenerator
var test_level_data: Dictionary

func before_each():
	level_generator = LevelGenerator.new()
	add_child_autofree(level_generator)
	
	# 等待场景预加载完成
	await wait_frames(1)
	
	# 准备测试数据
	test_level_data = {
		"level_id": 999,
		"level_name": "测试关卡",
		"player": {"position": [100, 200]},
		"camera": {
			"position": [0, -10],
			"zoom": [2, 2],
			"limit_left": -100,
			"limit_bottom": 100,
			"smooth": true
		},
		"killzone": {"y_position": 500},
		"coins": [
			{"position": [50, 50]},
			{"position": [100, 50]},
			{"position": [150, 50]}
		],
		"platforms": [
			{"position": [200, 100], "is_moving": false},
			{
				"position": [300, 100],
				"is_moving": true,
				"move_target": [400, 100],
				"move_duration": 2.0,
				"loop_mode": "pingpong"
			}
		],
		"enemies": [
			{"type": "slime", "position": [250, 80]}
		],
		"portal": {
			"position": [500, 50],
			"destination_scene": "res://scenes/levels/lv2.tscn"
		}
	}

func after_each():
	test_level_data.clear()

# 测试场景缓存预加载
func test_scene_cache_preloaded():
	assert_not_null(level_generator._scene_cache, "场景缓存应该被初始化")
	assert_true(level_generator._scene_cache.has("player"), "应该预加载player场景")
	assert_true(level_generator._scene_cache.has("coin"), "应该预加载coin场景")
	assert_true(level_generator._scene_cache.has("platform"), "应该预加载platform场景")
	assert_true(level_generator._scene_cache.has("slime"), "应该预加载slime场景")
	assert_true(level_generator._scene_cache.has("portal"), "应该预加载portal场景")

# 测试JSON加载（有效文件）
func test_load_json_valid_file():
	var json_data = level_generator._load_json("res://resources/level_data/lv1_data.json")
	assert_false(json_data.is_empty(), "应该成功加载有效的JSON文件")
	assert_eq(json_data.get("level_id"), 1, "应该正确解析level_id")
	assert_has(json_data, "level_name", "应该包含level_name字段")

# 测试JSON加载（无效文件）
func test_load_json_invalid_file():
	var json_data = level_generator._load_json("res://nonexistent.json")
	assert_true(json_data.is_empty(), "不存在的文件应该返回空字典")

# 测试从Dictionary生成关卡
func test_generate_level_from_dict():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "应该成功生成关卡")
	assert_true(level is Node2D, "生成的关卡应该是Node2D类型")
	assert_eq(level.name, "Level999", "关卡名称应该正确")

# 测试玩家创建
func test_player_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var player = level.get_node_or_null("Player")
	assert_not_null(player, "应该创建玩家节点")
	assert_eq(player.position, Vector2(100, 200), "玩家位置应该正确")

# 测试相机创建
func test_camera_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var camera = level.get_node_or_null("Camera2D")
	assert_not_null(camera, "应该创建相机节点")
	assert_eq(camera.position, Vector2(0, -10), "相机位置应该正确")
	assert_eq(camera.zoom, Vector2(2, 2), "相机缩放应该正确")
	assert_eq(camera.limit_left, -100, "相机左边界应该正确")
	assert_true(camera.position_smoothing_enabled, "相机平滑应该启用")

# 测试金币创建
func test_coins_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var coins_container = level.get_node_or_null("Coins")
	assert_not_null(coins_container, "应该创建Coins容器")
	assert_eq(coins_container.get_child_count(), 3, "应该创建3个金币")
	
	var first_coin = coins_container.get_child(0)
	assert_eq(first_coin.position, Vector2(50, 50), "第一个金币位置应该正确")

# 测试平台创建
func test_platforms_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var platforms_container = level.get_node_or_null("Platforms")
	assert_not_null(platforms_container, "应该创建Platforms容器")
	assert_eq(platforms_container.get_child_count(), 2, "应该创建2个平台")

# 测试移动平台动画
func test_moving_platform_animation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var platforms_container = level.get_node_or_null("Platforms")
	var moving_platform = platforms_container.get_child(1)  # 第二个平台是移动平台
	
	var anim_player = moving_platform.get_node_or_null("AnimationPlayer")
	assert_not_null(anim_player, "移动平台应该有AnimationPlayer")
	assert_true(anim_player.has_animation("move"), "应该有move动画")
	assert_true(anim_player.is_playing(), "动画应该正在播放")

# 测试敌人创建
func test_enemies_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var monsters_container = level.get_node_or_null("Monster")
	assert_not_null(monsters_container, "应该创建Monster容器")
	assert_eq(monsters_container.get_child_count(), 1, "应该创建1个敌人")
	
	var slime = monsters_container.get_child(0)
	assert_eq(slime.position, Vector2(250, 80), "史莱姆位置应该正确")

# 测试传送门创建
func test_portal_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var portal = level.get_node_or_null("Portal")
	assert_not_null(portal, "应该创建传送门")
	assert_eq(portal.position, Vector2(500, 50), "传送门位置应该正确")

# 测试从文件生成关卡
func test_generate_level_from_file():
	var level = level_generator.generate_level_from_file("res://resources/level_data/lv1_data.json")
	assert_not_null(level, "应该成功从文件生成关卡")
	assert_eq(level.name, "Level1", "关卡名称应该正确")

# 测试GameManager创建
func test_game_manager_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var game_manager = level.get_node_or_null("GameManager")
	assert_not_null(game_manager, "应该创建GameManager")

# 测试UI创建
func test_ui_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "关卡应该成功生成")
	
	var ui = level.get_node_or_null("UI")
	assert_not_null(ui, "应该创建UI")

# 测试空数据处理
func test_empty_data_handling():
	var level = level_generator.generate_level({})
	assert_null(level, "空数据应该返回null")

# 测试缺少必要字段时的处理
func test_minimal_data():
	var minimal_data = {
		"level_id": 1,
		"level_name": "最小关卡"
	}
	var level = level_generator.generate_level(minimal_data)
	assert_not_null(level, "即使数据最小，也应该能生成关卡")
	assert_eq(level.name, "Level1", "关卡名称应该正确")
