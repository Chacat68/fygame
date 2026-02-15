extends GutTest

# LevelGenerator 单元测试
# 测试数据驱动的关卡生成系统

var level_generator: LevelGenerator
var test_level_data: Dictionary

func before_each():
	level_generator = LevelGenerator.new()
	add_child_autofree(level_generator)

	# 等待一帧，确保 _ready() 完成场景预加载
	await wait_frames(1)

	# 准备测试数据
	test_level_data = {
		"level_id": 999,
		"level_name": "测试关卡",
		"player": {"position": [100, 200]},
		"camera": {
			"position": [0, -10],
			"zoom": [2, 2],
			"limit_left": - 100,
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

# ── 场景缓存 ──────────────────────────────────────────

func test_scene_cache_preloaded():
	assert_not_null(level_generator._scene_cache, "场景缓存应该被初始化")
	assert_true(level_generator._scene_cache.has("player"), "应该预加载player场景")
	assert_true(level_generator._scene_cache.has("coin"), "应该预加载coin场景")
	assert_true(level_generator._scene_cache.has("platform"), "应该预加载platform场景")
	assert_true(level_generator._scene_cache.has("slime"), "应该预加载slime场景")
	assert_true(level_generator._scene_cache.has("portal"), "应该预加载portal场景")
	assert_true(level_generator._scene_cache.has("checkpoint"), "应该预加载checkpoint场景")

# ── JSON 处理 ─────────────────────────────────────────

func test_load_json_valid_file():
	var json_data = level_generator._load_json("res://resources/level_data/lv1_data.json")
	assert_false(json_data.is_empty(), "应该成功加载有效的JSON文件")
	assert_eq(json_data.get("level_id"), 1, "应该正确解析level_id")
	assert_has(json_data, "level_name", "应该包含level_name字段")

func test_load_json_invalid_file():
	var json_data = level_generator._load_json("res://nonexistent.json")
	assert_true(json_data.is_empty(), "不存在的文件应该返回空字典")

# ── 数据校验 ──────────────────────────────────────────

func test_validate_data_empty():
	assert_false(level_generator._validate_data({}), "空数据应该校验失败")

func test_validate_data_missing_level_id():
	assert_false(level_generator._validate_data({"level_name": "test"}), "缺少level_id应校验失败")

func test_validate_data_valid():
	assert_true(level_generator._validate_data({"level_id": 1}), "有level_id应校验通过")

# ── 关卡生成 ──────────────────────────────────────────

func test_generate_level_from_dict():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level, "应该成功生成关卡")
	assert_true(level is Node2D, "生成的关卡应该是Node2D类型")
	assert_eq(level.name, "Level999", "关卡名称应该正确")

func test_generate_level_emits_signal():
	watch_signals(level_generator)
	var level = level_generator.generate_level(test_level_data)
	assert_signal_emitted(level_generator, "level_generated", "应该发出level_generated信号")

func test_empty_data_handling():
	var level = level_generator.generate_level({})
	assert_null(level, "空数据应该返回null")

func test_minimal_data():
	var minimal_data = {"level_id": 1, "level_name": "最小关卡"}
	var level = level_generator.generate_level(minimal_data)
	assert_not_null(level, "即使数据最小，也应该能生成关卡")
	assert_eq(level.name, "Level1", "关卡名称应该正确")

# ── 玩家 ──────────────────────────────────────────────

func test_player_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	var player = level.get_node_or_null("Player")
	assert_not_null(player, "应该创建玩家节点")
	assert_eq(player.position, Vector2(100, 200), "玩家位置应该正确")

# ── 相机 ──────────────────────────────────────────────

func test_camera_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	var camera = level.get_node_or_null("Camera2D")
	assert_not_null(camera, "应该创建相机节点")
	assert_eq(camera.position, Vector2(0, -10), "相机位置应该正确")
	assert_eq(camera.zoom, Vector2(2, 2), "相机缩放应该正确")
	assert_eq(camera.limit_left, -100, "相机左边界应该正确")
	assert_true(camera.position_smoothing_enabled, "相机平滑应该启用")

# ── 金币 ──────────────────────────────────────────────

func test_coins_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	var coins_container = level.get_node_or_null("Coins")
	assert_not_null(coins_container, "应该创建Coins容器")
	assert_eq(coins_container.get_child_count(), 3, "应该创建3个金币")
	assert_eq(coins_container.get_child(0).position, Vector2(50, 50), "第一个金币位置应该正确")

# ── 平台 ──────────────────────────────────────────────

func test_platforms_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	var pf = level.get_node_or_null("Platforms")
	assert_not_null(pf, "应该创建Platforms容器")
	assert_eq(pf.get_child_count(), 2, "应该创建2个平台")

func test_moving_platform_animation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	var moving = level.get_node_or_null("Platforms").get_child(1)
	var anim_player = moving.get_node_or_null("AnimationPlayer")
	assert_not_null(anim_player, "移动平台应该有AnimationPlayer")
	assert_true(anim_player.has_animation("move"), "应该有move动画")
	assert_true(anim_player.is_playing(), "动画应该正在播放")

func test_moving_platform_simplified_config():
	var data = test_level_data.duplicate(true)
	data["platforms"] = [
		{
			"position": [100, 100],
			"is_moving": true,
			"move_distance": 80,
			"move_direction": "vertical"
		}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var platform = level.get_node_or_null("Platforms").get_child(0)
	var ap = platform.get_node_or_null("AnimationPlayer")
	assert_not_null(ap, "移动平台应该有AnimationPlayer")
	assert_true(ap.is_playing(), "动画应该正在播放")

# ── 敌人 ──────────────────────────────────────────────

func test_enemies_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	var monsters = level.get_node_or_null("Monster")
	assert_not_null(monsters, "应该创建Monster容器")
	assert_eq(monsters.get_child_count(), 1, "应该创建1个敌人")
	assert_eq(monsters.get_child(0).position, Vector2(250, 80), "史莱姆位置应该正确")

func test_purple_slime_creation():
	var data = test_level_data.duplicate(true)
	data["enemies"] = [
		{"type": "slime", "position": [300, 100], "is_purple": true}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var monsters = level.get_node_or_null("Monster")
	assert_eq(monsters.get_child_count(), 1, "应该创建1个敌人")
	assert_eq(monsters.get_child(0).position, Vector2(300, 100), "紫色史莱姆位置应该正确")

# ── 检查点 ────────────────────────────────────────────

func test_checkpoint_creation():
	var data = test_level_data.duplicate(true)
	data["checkpoints"] = [
		{"position": [400, 100]},
		{"position": [800, 200]}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var cps = level.get_node_or_null("Checkpoints")
	assert_not_null(cps, "应该创建Checkpoints容器")
	assert_eq(cps.get_child_count(), 2, "应该创建2个检查点")
	assert_eq(cps.get_child(0).position, Vector2(400, 100), "第一个检查点位置应该正确")

# ── Hazards ───────────────────────────────────────────

func test_hazards_creation():
	var data = test_level_data.duplicate(true)
	data["hazards"] = [
		{"type": "spikes", "position": [100, 50], "config": {"damage": 20}},
		{"type": "springboard", "position": [200, 50], "config": {"bounce_force": 500.0}}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var hazards = level.get_node_or_null("Hazards")
	assert_not_null(hazards, "应该创建Hazards容器")
	assert_eq(hazards.get_child_count(), 2, "应该创建2个hazard")

func test_hazard_config_applied():
	var data = test_level_data.duplicate(true)
	data["hazards"] = [
		{"type": "spikes", "position": [100, 50], "config": {"damage": 30, "damage_cooldown": 1.0}}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var spike = level.get_node_or_null("Hazards").get_child(0)
	assert_eq(spike.damage, 30, "damage 应该被正确配置")
	assert_eq(spike.damage_cooldown, 1.0, "damage_cooldown 应该被正确配置")

func test_hazard_unknown_type_skipped():
	var data = test_level_data.duplicate(true)
	data["hazards"] = [
		{"type": "unknown_hazard", "position": [100, 50]}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var hazards = level.get_node_or_null("Hazards")
	assert_not_null(hazards)
	assert_eq(hazards.get_child_count(), 0, "未知类型应该被跳过")

func test_multiple_hazard_types():
	var data = test_level_data.duplicate(true)
	data["hazards"] = [
		{"type": "spikes", "position": [50, 88], "config": {}},
		{"type": "pressure_switch", "position": [100, 88], "config": {}},
		{"type": "laser_beam", "position": [200, 50], "config": {"damage": 10}}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var hazards = level.get_node_or_null("Hazards")
	assert_eq(hazards.get_child_count(), 3, "应该创建3个不同类型的hazard")

# ── Labels ────────────────────────────────────────────

func test_labels_creation():
	var data = test_level_data.duplicate(true)
	data["labels"] = [
		{"position": [100, 50], "text": "提示1"},
		{"position": [200, 60], "text": "提示2", "font_size": 24}
	]
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var labels = level.get_node_or_null("Labels")
	assert_not_null(labels, "应该创建Labels容器")
	assert_eq(labels.get_child_count(), 2, "应该创建2个标签")

	var label1 = labels.get_child(0) as Label
	assert_eq(label1.text, "提示1", "标签文字应该正确")
	assert_eq(label1.position, Vector2(100, 50), "标签位置应该正确")

func test_labels_empty_array():
	var data = test_level_data.duplicate(true)
	data["labels"] = []
	var level = level_generator.generate_level(data)
	assert_not_null(level)
	var labels = level.get_node_or_null("Labels")
	assert_not_null(labels, "即使空数组也应创建Labels容器")
	assert_eq(labels.get_child_count(), 0, "空数组不应创建标签")

# ── 传送门 ────────────────────────────────────────────

func test_portal_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	var portal = level.get_node_or_null("Portal")
	assert_not_null(portal, "应该创建传送门")
	assert_eq(portal.position, Vector2(500, 50), "传送门位置应该正确")

# ── GameManager / UI ──────────────────────────────────

func test_game_manager_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	assert_not_null(level.get_node_or_null("GameManager"), "应该创建GameManager")

func test_ui_creation():
	var level = level_generator.generate_level(test_level_data)
	assert_not_null(level)
	assert_not_null(level.get_node_or_null("UI"), "应该创建UI")

# ── 从文件生成 ────────────────────────────────────────

func test_generate_level_from_file():
	var level = level_generator.generate_level_from_file("res://resources/level_data/lv1_data.json")
	assert_not_null(level, "应该成功从文件生成关卡")
	assert_eq(level.name, "Level1", "关卡名称应该正确")
