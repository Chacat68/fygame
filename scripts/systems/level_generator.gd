# 程序化关卡生成器
# 从 JSON 数据文件动态生成关卡场景（唯一入口）
class_name LevelGenerator
extends Node

# 信号
signal level_generated(root: Node2D)

# 场景缓存
var _scene_cache: Dictionary = {}

# hazard 类映射
const HAZARD_CLASSES := {
	"spikes": "Spikes",
	"saw_blade": "SawBlade",
	"springboard": "Springboard",
	"crumbling_platform": "CrumblingPlatform",
	"interactive_door": "InteractiveDoor",
	"pressure_switch": "PressureSwitch",
	"laser_beam": "LaserBeam",
	"advanced_moving_platform": "AdvancedMovingPlatform"
}

# hazard 碰撞形状默认尺寸
const HAZARD_SHAPES := {
	"spikes": Vector2(32, 8),
	"saw_blade": 12.0, # 圆形半径
	"springboard": Vector2(24, 6),
	"crumbling_platform": Vector2(48, 10),
	"interactive_door": Vector2(12, 48),
	"pressure_switch": Vector2(24, 4),
	"laser_beam": Vector2.ZERO, # LaserBeam 自建组件
	"advanced_moving_platform": Vector2(48, 10)
}

func _ready():
	_preload_scenes()

# 预加载实体场景
func _preload_scenes():
	_scene_cache["player"] = preload("res://scenes/entities/player.tscn")
	_scene_cache["coin"] = preload("res://scenes/entities/coin.tscn")
	_scene_cache["platform"] = preload("res://scenes/entities/platform.tscn")
	_scene_cache["slime"] = preload("res://scenes/entities/slime.tscn")
	_scene_cache["killzone"] = preload("res://scenes/entities/killzone.tscn")
	_scene_cache["portal"] = preload("res://scenes/entities/portal.tscn")
	_scene_cache["checkpoint"] = preload("res://scenes/entities/checkpoint.tscn")
	_scene_cache["game_manager"] = preload("res://scenes/managers/game_manager.tscn")
	_scene_cache["ui"] = preload("res://scenes/ui/ui.tscn")

# ── 公开接口 ──────────────────────────────────────────

## 从 JSON 文件路径生成关卡
func generate_level_from_file(json_path: String) -> Node2D:
	var data = _load_json(json_path)
	if data.is_empty():
		push_error("[LevelGenerator] 无法加载: " + json_path)
		return null
	return generate_level(data)

## 从 Dictionary 数据生成关卡
func generate_level(data: Dictionary) -> Node2D:
	if not _validate_data(data):
		return null

	var root = Node2D.new()
	root.name = "Level%d" % data.get("level_id", 0)

	# 按顺序创建场景元素
	_add_scene_node(root, "game_manager", "GameManager")
	_add_scene_node(root, "ui", "UI")

	# 纯程序化生成地形（不再依赖外部 .tscn）
	if data.has("ground"):
		_create_ground(root, data["ground"])
	if data.has("player"):
		_create_player(root, data["player"])
	if data.has("camera"):
		_create_camera(root, data["camera"])
	if data.has("killzone"):
		_create_killzone(root, data["killzone"])
	if data.has("coins"):
		_create_batch(root, "Coins", "coin", data["coins"])
	if data.has("platforms"):
		_create_platforms(root, data["platforms"])
	if data.has("enemies"):
		_create_enemies(root, data["enemies"])
	if data.has("checkpoints"):
		_create_batch(root, "Checkpoints", "checkpoint", data["checkpoints"])
	if data.has("hazards"):
		_create_hazards(root, data["hazards"])
	if data.has("labels"):
		_create_labels(root, data["labels"])
	if data.has("boss"):
		_create_boss(root, data["boss"])
	if data.has("portal"):
		_create_portal(root, data["portal"])

	level_generated.emit(root)
	return root

# ── JSON 加载与校验 ───────────────────────────────────

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[LevelGenerator] JSON 文件不存在: " + path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[LevelGenerator] 无法打开: " + path)
		return {}

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("[LevelGenerator] JSON 解析错误 (行 %d): %s" % [json.get_error_line(), json.get_error_message()])
		return {}

	return json.data

## 校验关卡数据的必要字段
func _validate_data(data: Dictionary) -> bool:
	if data.is_empty():
		push_error("[LevelGenerator] 关卡数据为空")
		return false

	if not data.has("level_id"):
		push_error("[LevelGenerator] 缺少必要字段: level_id")
		return false

	return true

# ── 通用工具 ──────────────────────────────────────────

## 实例化并添加一个缓存场景
func _add_scene_node(root: Node2D, cache_key: String, node_name: String) -> Node:
	if not _scene_cache.has(cache_key):
		push_error("[LevelGenerator] 场景未缓存: " + cache_key)
		return null
	var node = _scene_cache[cache_key].instantiate()
	node.name = node_name
	root.add_child(node)
	return node

## 批量创建同类实体（金币 / 检查点等简单实体）
func _create_batch(root: Node2D, container_name: String, cache_key: String, items: Array):
	if not _scene_cache.has(cache_key):
		push_error("[LevelGenerator] 场景未缓存: " + cache_key)
		return

	var container = Node2D.new()
	container.name = container_name
	root.add_child(container)

	for item in items:
		var node = _scene_cache[cache_key].instantiate()
		if item.has("position"):
			var pos = item["position"]
			node.position = Vector2(pos[0], pos[1])
		container.add_child(node)

## 从 JSON 数组读取 Vector2
func _parse_vec2(arr: Array) -> Vector2:
	if arr.size() >= 2:
		return Vector2(arr[0], arr[1])
	return Vector2.ZERO

## 递归清除节点 owner，避免跨场景挂载时的 inconsistent 警告
func _clear_owner_recursive(node: Node):
	node.owner = null
	for child in node.get_children():
		_clear_owner_recursive(child)

# ── 特定实体创建 ──────────────────────────────────────

func _create_player(root: Node2D, player_data: Dictionary):
	var player = _add_scene_node(root, "player", "Player")
	if player and player_data.has("position"):
		player.position = _parse_vec2(player_data["position"])

func _create_camera(root: Node2D, cam_data: Dictionary):
	var camera = Camera2D.new()
	camera.name = "Camera2D"

	if cam_data.has("position"):
		camera.position = _parse_vec2(cam_data["position"])
	if cam_data.has("zoom"):
		camera.zoom = _parse_vec2(cam_data["zoom"])
	if cam_data.has("limit_left"):
		camera.limit_left = cam_data["limit_left"]
	if cam_data.has("limit_bottom"):
		camera.limit_bottom = cam_data["limit_bottom"]
	if cam_data.has("smooth"):
		camera.position_smoothing_enabled = cam_data["smooth"]

	root.add_child(camera)

func _create_killzone(root: Node2D, kz_data: Dictionary):
	var killzone = _add_scene_node(root, "killzone", "Killzone")
	if not killzone:
		return
	if kz_data.has("y_position"):
		killzone.position.y = kz_data["y_position"]

	var collision = CollisionShape2D.new()
	var shape = WorldBoundaryShape2D.new()
	shape.normal = Vector2(0, -1)
	collision.shape = shape
	killzone.add_child(collision)

## 纯程序化生成地形
## ground JSON 格式:
## {
##   "color": [r, g, b],          -- 地块颜色 (0-1)
##   "border_color": [r, g, b],   -- 边框颜色 (可选)
##   "segments": [
##     { "x": -200, "y": 100, "width": 400, "height": 32 },
##     { "x": 300, "y": 80, "width": 200, "height": 32 },
##     ...
##   ]
## }
func _create_ground(root: Node2D, ground_data: Dictionary):
	var container = Node2D.new()
	container.name = "Ground"
	root.add_child(container)

	# 解析颜色
	var ground_color = Color(0.35, 0.25, 0.18) # 默认土地棕色
	if ground_data.has("color"):
		var c = ground_data["color"]
		ground_color = Color(c[0], c[1], c[2])

	var border_color = ground_color.darkened(0.3)
	if ground_data.has("border_color"):
		var bc = ground_data["border_color"]
		border_color = Color(bc[0], bc[1], bc[2])

	# 若没有 segments，生成默认地块
	var segments = ground_data.get("segments", [])
	if segments.is_empty():
		segments = [
			{"x": - 400, "y": 120, "width": 1200, "height": 40}
		]

	for i in range(segments.size()):
		var seg = segments[i]
		var x = float(seg.get("x", 0))
		var y = float(seg.get("y", 120))
		var w = float(seg.get("width", 200))
		var h = float(seg.get("height", 32))

		_create_ground_segment(container, i, Vector2(x, y), Vector2(w, h), ground_color, border_color)

## 创建单个地块 segment（StaticBody2D + 可视化 + 碰撞）
func _create_ground_segment(parent: Node2D, index: int, pos: Vector2, size: Vector2, color: Color, border_color: Color):
	var body = StaticBody2D.new()
	body.name = "Ground_%d" % index
	body.position = pos + size / 2 # StaticBody 位置在中心
	parent.add_child(body)

	# 碰撞形状
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	# 可视化地块（主体）
	var rect = ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = - size / 2
	body.add_child(rect)

	# 上表面草地/边框效果
	var surface = ColorRect.new()
	surface.color = border_color
	surface.size = Vector2(size.x, 3)
	surface.position = Vector2(-size.x / 2, -size.y / 2)
	body.add_child(surface)

	# 左侧边框
	var left_border = ColorRect.new()
	left_border.color = border_color
	left_border.size = Vector2(2, size.y)
	left_border.position = Vector2(-size.x / 2, -size.y / 2)
	body.add_child(left_border)

	# 右侧边框
	var right_border = ColorRect.new()
	right_border.color = border_color
	right_border.size = Vector2(2, size.y)
	right_border.position = Vector2(size.x / 2 - 2, -size.y / 2)
	body.add_child(right_border)

# ── 平台 ──────────────────────────────────────────────

func _create_platforms(root: Node2D, platforms_data: Array):
	if not _scene_cache.has("platform"):
		push_error("[LevelGenerator] Platform 场景未缓存")
		return

	var container = Node2D.new()
	container.name = "Platforms"
	root.add_child(container)

	for pd in platforms_data:
		var platform = _scene_cache["platform"].instantiate()

		if pd.has("position"):
			platform.position = _parse_vec2(pd["position"])

		if pd.get("is_moving", false):
			_setup_moving_platform(platform, pd)

		container.add_child(platform)

func _setup_moving_platform(platform: Node, pd: Dictionary):
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	platform.add_child(anim_player)

	var anim_lib = AnimationLibrary.new()

	# RESET 动画
	var reset_anim = Animation.new()
	reset_anim.length = 0.001
	var reset_track = reset_anim.add_track(Animation.TYPE_VALUE)
	reset_anim.track_set_path(reset_track, ":position")
	reset_anim.track_insert_key(reset_track, 0.0, Vector2.ZERO)
	anim_lib.add_animation("RESET", reset_anim)

	# move 动画
	var move_duration = pd.get("move_duration", 1.3)
	var move_anim = Animation.new()
	move_anim.length = move_duration * 2

	var move_track = move_anim.add_track(Animation.TYPE_VALUE)
	move_anim.track_set_path(move_track, ":position")

	# 计算移动目标（支持两种配置方式）
	var move_target = Vector2.ZERO
	if pd.has("move_target") and pd.has("position"):
		var t = pd["move_target"]
		var p = pd["position"]
		move_target = Vector2(t[0], t[1]) - Vector2(p[0], p[1])
	elif pd.has("move_distance"):
		var dist = pd["move_distance"]
		var dir = pd.get("move_direction", "horizontal")
		match dir:
			"horizontal":
				move_target = Vector2(dist, 0)
			"vertical":
				move_target = Vector2(0, dist)
	else:
		move_target = Vector2(60, 0)

	move_anim.track_insert_key(move_track, 0.0, Vector2.ZERO)
	move_anim.track_insert_key(move_track, move_duration, move_target)

	var loop_mode = pd.get("loop_mode", "pingpong")
	move_anim.loop_mode = Animation.LOOP_PINGPONG if loop_mode == "pingpong" else Animation.LOOP_LINEAR

	anim_lib.add_animation("move", move_anim)
	anim_player.add_animation_library("", anim_lib)
	anim_player.play("move")

# ── 敌人 ──────────────────────────────────────────────

func _create_enemies(root: Node2D, enemies_data: Array):
	var container = Node2D.new()
	container.name = "Monster"
	root.add_child(container)

	for ed in enemies_data:
		var enemy_type = ed.get("type", "slime")
		if not _scene_cache.has(enemy_type):
			push_warning("[LevelGenerator] 未知敌人类型: " + enemy_type)
			continue

		var enemy = _scene_cache[enemy_type].instantiate()

		if ed.has("position"):
			enemy.position = _parse_vec2(ed["position"])

		# 紫色史莱姆变体
		if ed.get("is_purple", false) and enemy_type == "slime":
			_apply_purple_slime(enemy)

		container.add_child(enemy)

## 将普通史莱姆变为紫色变体（更快速度 + 紫色贴图）
func _apply_purple_slime(slime: Node):
	var sprite = slime.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return

	sprite.sprite_frames.set_animation_speed("default", 10)

	var texture = load("res://assets/sprites/slime_purple.png")
	if texture:
		for i in range(sprite.sprite_frames.get_frame_count("default")):
			var old_atlas = sprite.sprite_frames.get_frame_texture("default", i)
			if old_atlas is AtlasTexture:
				var new_atlas = AtlasTexture.new()
				new_atlas.atlas = texture
				new_atlas.region = old_atlas.region
				sprite.sprite_frames.set_frame("default", i, new_atlas)

	if "SPEED" in slime:
		slime.SPEED = 60

# ── Hazards（机关陷阱）────────────────────────────────

func _create_hazards(root: Node2D, hazards_data: Array):
	var container = Node2D.new()
	container.name = "Hazards"
	root.add_child(container)

	for hd in hazards_data:
		var hazard_type = hd.get("type", "")
		if hazard_type.is_empty() or not HAZARD_CLASSES.has(hazard_type):
			push_warning("[LevelGenerator] 未知 hazard 类型: " + hazard_type)
			continue

		var hazard = _create_hazard_node(hazard_type)
		if not hazard:
			continue

		if hd.has("position"):
			hazard.position = _parse_vec2(hd["position"])

		# 应用自定义配置
		if hd.has("config"):
			_apply_hazard_config(hazard, hd["config"])

		container.add_child(hazard)

## 创建 hazard 节点实例
func _create_hazard_node(hazard_type: String) -> Node:
	match hazard_type:
		"spikes":
			return _new_spikes()
		"saw_blade":
			return _new_saw_blade()
		"springboard":
			return _new_springboard()
		"crumbling_platform":
			return _new_crumbling_platform()
		"interactive_door":
			return _new_interactive_door()
		"pressure_switch":
			return _new_pressure_switch()
		"laser_beam":
			return _new_laser_beam()
		"advanced_moving_platform":
			return _new_advanced_moving_platform()
		_:
			push_warning("[LevelGenerator] 未实现的 hazard 类型: " + hazard_type)
			return null

## 通用：将 config 字典映射到节点的 @export 属性
func _apply_hazard_config(node: Node, config: Dictionary):
	for key in config.keys():
		if key in node:
			var value = config[key]
			node.set(key, value)

# ── Hazard 工厂方法 ───────────────────────────────────

func _new_spikes() -> Node:
	var node = Spikes.new()
	node.name = "Spikes"
	_add_collision_rect(node, HAZARD_SHAPES["spikes"])
	_add_placeholder_sprite(node, HAZARD_SHAPES["spikes"], Color(0.8, 0.2, 0.2))
	return node

func _new_saw_blade() -> Node:
	var node = SawBlade.new()
	node.name = "SawBlade"
	_add_collision_circle(node, HAZARD_SHAPES["saw_blade"])
	_add_placeholder_sprite_circle(node, HAZARD_SHAPES["saw_blade"], Color(0.9, 0.5, 0.0))
	return node

func _new_springboard() -> Node:
	var node = Springboard.new()
	node.name = "Springboard"
	_add_collision_rect(node, HAZARD_SHAPES["springboard"])
	_add_placeholder_sprite(node, HAZARD_SHAPES["springboard"], Color(0.2, 0.8, 0.2))
	return node

func _new_crumbling_platform() -> Node:
	var node = CrumblingPlatform.new()
	node.name = "CrumblingPlatform"
	_add_collision_rect(node, HAZARD_SHAPES["crumbling_platform"])
	_add_placeholder_sprite(node, HAZARD_SHAPES["crumbling_platform"], Color(0.6, 0.5, 0.3))
	return node

func _new_interactive_door() -> Node:
	var node = InteractiveDoor.new()
	node.name = "InteractiveDoor"
	# InteractiveDoor 内部自建 DoorBody/CollisionShape2D
	return node

func _new_pressure_switch() -> Node:
	var node = PressureSwitch.new()
	node.name = "PressureSwitch"
	_add_collision_rect(node, HAZARD_SHAPES["pressure_switch"])
	_add_placeholder_sprite(node, HAZARD_SHAPES["pressure_switch"], Color(0.3, 0.7, 0.9))
	return node

func _new_laser_beam() -> Node:
	var node = LaserBeam.new()
	node.name = "LaserBeam"
	# LaserBeam 在 _ready() 中自建所有组件
	return node

func _new_advanced_moving_platform() -> Node:
	var node = AdvancedMovingPlatform.new()
	node.name = "AdvancedMovingPlatform"
	_add_collision_rect(node, HAZARD_SHAPES["advanced_moving_platform"])
	_add_placeholder_sprite(node, HAZARD_SHAPES["advanced_moving_platform"], Color(0.5, 0.5, 0.7))
	return node

# ── Hazard 辅助：碰撞形状和占位精灵 ──────────────────

func _add_collision_rect(node: Node, size: Vector2):
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	node.add_child(collision)

func _add_collision_circle(node: Node, radius: float):
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	node.add_child(collision)

func _add_placeholder_sprite(node: Node, size: Vector2, color: Color):
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	# 使用 ColorRect 作为临时占位视觉
	var rect = ColorRect.new()
	rect.name = "PlaceholderVisual"
	rect.size = size
	rect.position = - size / 2
	rect.color = color
	node.add_child(rect)

func _add_placeholder_sprite_circle(node: Node, radius: float, color: Color):
	var rect = ColorRect.new()
	rect.name = "PlaceholderVisual"
	rect.size = Vector2(radius * 2, radius * 2)
	rect.position = Vector2(-radius, -radius)
	rect.color = color
	node.add_child(rect)

# ── Labels（提示文字）─────────────────────────────────

func _create_labels(root: Node2D, labels_data: Array):
	var container = Node2D.new()
	container.name = "Labels"
	root.add_child(container)

	for ld in labels_data:
		var label = Label.new()

		if ld.has("name"):
			label.name = ld["name"]
		else:
			label.name = "Label"

		if ld.has("position"):
			var pos = ld["position"]
			label.position = Vector2(pos[0], pos[1])

		label.text = ld.get("text", "")

		if ld.has("font_size"):
			label.add_theme_font_size_override("font_size", ld["font_size"])

		if ld.has("color"):
			var c = ld["color"]
			label.add_theme_color_override("font_color", Color(c[0], c[1], c[2], c.get(3, 1.0) if c.size() > 3 else 1.0))

		container.add_child(label)

# ── 传送门 ────────────────────────────────────────────

func _create_portal(root: Node2D, portal_data: Dictionary):
	var portal = _add_scene_node(root, "portal", "Portal")
	if not portal:
		return

	if portal_data.has("position"):
		portal.position = _parse_vec2(portal_data["position"])

	if portal_data.has("destination_scene"):
		var dest = portal_data["destination_scene"]
		# 使用 set() 安全赋值，避免脚本属性直接访问失败
		portal.set("destination_scene", dest)
		portal.set("next_level", -1)
		if not ResourceLoader.exists(dest):
			push_warning("[LevelGenerator] 目标场景不存在: " + dest)

# ── Boss 生成 ─────────────────────────────────────────

func _create_boss(root: Node2D, boss_data: Dictionary):
	var boss_type = boss_data.get("type", "")
	if boss_type != "void_guardian":
		push_warning("[LevelGenerator] 未知 boss 类型: " + boss_type)
		return

	var boss = VoidGuardian.new()
	boss.name = "VoidGuardian"

	if boss_data.has("position"):
		boss.position = _parse_vec2(boss_data["position"])

	# 应用配置
	if boss_data.has("config"):
		var config = boss_data["config"]
		for key in config.keys():
			if key in boss:
				boss.set(key, config[key])

	root.add_child(boss)
