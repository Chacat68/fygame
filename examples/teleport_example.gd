extends Node2D

# 传送系统使用示例
# 这个脚本展示了如何在游戏中集成和使用新的传送系统

class_name TeleportExample

@onready var teleport_manager: TeleportManager
@onready var player: CharacterBody2D
@onready var ui_label: Label
@onready var teleport_button: Button
@onready var config_option: OptionButton

# 预设配置选项
var preset_configs = {
	"瞬间传送": TeleportConfig.TeleportPreset.INSTANT,
	"平滑传送": TeleportConfig.TeleportPreset.SMOOTH,
	"电影式传送": TeleportConfig.TeleportPreset.CINEMATIC,
	"调试模式": TeleportConfig.TeleportPreset.DEBUG
}

func _ready():
	# 初始化传送管理器
	_setup_teleport_manager()
	
	# 设置UI
	_setup_ui()
	
	# 连接信号
	_connect_signals()

func _setup_teleport_manager():
	# 创建传送管理器
	teleport_manager = TeleportManager.new()
	add_child(teleport_manager)
	
	# 加载默认配置
	var config = load("res://resources/default_teleport_config.tres") as TeleportConfig
	if config:
		teleport_manager.set_config(config)
		print("[TeleportExample] 传送配置加载成功")
	else:
		print("[TeleportExample] 警告：无法加载传送配置，使用默认设置")

func _setup_ui():
	# 查找UI元素
	ui_label = get_node_or_null("UI/InfoLabel")
	teleport_button = get_node_or_null("UI/TeleportButton")
	config_option = get_node_or_null("UI/ConfigOption")
	
	# 设置配置选项
	if config_option:
		for preset_name in preset_configs.keys():
			config_option.add_item(preset_name)
		config_option.selected = 0  # 默认选择第一个
	
	# 更新UI显示
	_update_ui_info()

func _connect_signals():
	# 连接传送管理器信号
	teleport_manager.teleport_started.connect(_on_teleport_started)
	teleport_manager.teleport_completed.connect(_on_teleport_completed)
	teleport_manager.teleport_failed.connect(_on_teleport_failed)
	teleport_manager.teleport_cooldown_finished.connect(_on_teleport_cooldown_finished)
	
	# 连接UI信号
	if teleport_button:
		teleport_button.pressed.connect(_on_teleport_button_pressed)
	
	if config_option:
		config_option.item_selected.connect(_on_config_changed)

func _update_ui_info():
	if not ui_label:
		return
	
	var config = teleport_manager.get_config()
	var info_text = "传送系统状态:\n"
	info_text += "- 冷却时间: %.1f秒\n" % config.cooldown_time
	info_text += "- 传送距离限制: %.0f像素\n" % config.max_teleport_distance
	info_text += "- 特效启用: %s\n" % ("是" if config.enable_teleport_effects else "否")
	info_text += "- 传送偏移: %s\n" % str(config.portal_offset)
	
	if teleport_manager.is_teleporting:
		info_text += "\n状态: 传送中..."
	elif not teleport_manager.can_teleport():
		info_text += "\n状态: 冷却中"
	else:
		info_text += "\n状态: 就绪"
	
	ui_label.text = info_text

# 传送按钮点击事件
func _on_teleport_button_pressed():
	if not teleport_manager.can_teleport():
		print("[TeleportExample] 传送冷却中，请稍后再试")
		return
	
	# 执行传送到Portal
	teleport_manager.teleport_to_portal()

# 配置选项改变事件
func _on_config_changed(index: int):
	var preset_names = preset_configs.keys()
	if index < 0 or index >= preset_names.size():
		return
	
	var preset_name = preset_names[index]
	var preset = preset_configs[preset_name]
	
	# 创建新配置并应用预设
	var new_config = TeleportConfig.new()
	new_config.apply_preset(preset)
	
	# 应用到传送管理器
	teleport_manager.set_config(new_config)
	
	print("[TeleportExample] 切换到配置预设: ", preset_name)
	_update_ui_info()

# 传送事件回调函数
func _on_teleport_started(player_node: Node2D, destination: Vector2):
	print("[TeleportExample] 传送开始: ", destination)
	_update_ui_info()
	
	# 禁用传送按钮
	if teleport_button:
		teleport_button.disabled = true

func _on_teleport_completed(player_node: Node2D, destination: Vector2):
	print("[TeleportExample] 传送完成: ", destination)
	_update_ui_info()

func _on_teleport_failed(reason: String):
	print("[TeleportExample] 传送失败: ", reason)
	_update_ui_info()
	
	# 重新启用传送按钮
	if teleport_button:
		teleport_button.disabled = false

func _on_teleport_cooldown_finished():
	print("[TeleportExample] 传送冷却完成")
	_update_ui_info()
	
	# 重新启用传送按钮
	if teleport_button:
		teleport_button.disabled = false

# 创建自定义配置示例
func create_custom_config_example():
	var custom_config = TeleportConfig.new()
	
	# 自定义参数
	custom_config.portal_offset = Vector2(-50, 0)  # 更大的偏移
	custom_config.cooldown_time = 3.0  # 更长的冷却时间
	custom_config.teleport_duration = 1.0  # 添加传送动画
	custom_config.fade_out_duration = 0.5
	custom_config.fade_in_duration = 0.5
	custom_config.enable_teleport_effects = true
	custom_config.max_teleport_distance = 300.0  # 限制传送距离
	custom_config.log_teleport_events = true
	
	# 验证配置
	if custom_config.validate():
		teleport_manager.set_config(custom_config)
		print("[TeleportExample] 自定义配置应用成功")
	else:
		print("[TeleportExample] 自定义配置验证失败")

# 演示不同传送方式
func demonstrate_teleport_methods():
	# 方法1: 传送到Portal
	teleport_manager.teleport_to_portal()
	
	# 方法2: 传送到指定位置
	var target_position = Vector2(100, 100)
	teleport_manager.teleport_to_position(target_position)
	
	# 方法3: 传送指定玩家到Portal
	var specific_player = get_node_or_null("Player")
	if specific_player:
		teleport_manager.teleport_to_portal(specific_player)

# 性能监控示例
func _process(_delta):
	# 定期更新UI（可选）
	if randf() < 0.1:  # 10%的概率更新，避免每帧都更新
		_update_ui_info()