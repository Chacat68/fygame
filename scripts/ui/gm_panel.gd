extends PanelContainer

# GM面板脚本
# 提供调试功能，仅在调试模式下显示

# 组件引用
@onready var coin_input: SpinBox = $VBox/CoinRow/CoinInput
@onready var kill_input: SpinBox = $VBox/KillRow/KillInput
@onready var level_input: SpinBox = $VBox/LevelRow/LevelInput
@onready var god_mode_check: CheckBox = $VBox/GodModeCheck
@onready var speed_slider: HSlider = $VBox/SpeedRow/SpeedSlider
@onready var speed_label: Label = $VBox/SpeedRow/SpeedValue
@onready var vbox: VBoxContainer = $VBox
@onready var toggle_button: Button = $ToggleButton

# 状态
var god_mode: bool = false
var is_collapsed: bool = false

func _ready() -> void:
	# 连接 GameState 信号
	if GameState:
		GameState.debug_mode_changed.connect(_on_debug_mode_changed)
		# 初始化显示状态
		visible = GameState.debug_mode
	
	# 初始化值
	_refresh_values()

func _on_debug_mode_changed(enabled: bool) -> void:
	visible = enabled
	if enabled:
		_refresh_values()

# 刷新面板显示的值
func _refresh_values() -> void:
	# 获取 UI 节点
	var ui = _get_ui_node()
	if ui:
		if coin_input:
			coin_input.value = ui.coin_count
		if kill_input:
			kill_input.value = ui.kill_count
	
	if level_input and GameState:
		level_input.value = GameState.current_level
	
	if speed_slider:
		speed_slider.value = Engine.time_scale
		_update_speed_label()

# 更新速度显示
func _update_speed_label() -> void:
	if speed_label and speed_slider:
		speed_label.text = "%.1fx" % speed_slider.value

# 切换面板展开/收起
func _on_toggle_button_pressed() -> void:
	is_collapsed = not is_collapsed
	_update_panel_state()

# 更新面板状态
func _update_panel_state() -> void:
	if vbox:
		vbox.visible = not is_collapsed
	if toggle_button:
		toggle_button.text = "▶ GM" if is_collapsed else "▼ 收起"

# 金币数量改变
func _on_coin_input_value_changed(value: float) -> void:
	var ui = _get_ui_node()
	if ui:
		ui.update_coin_count(int(value), false)

# 击杀数量改变
func _on_kill_input_value_changed(value: float) -> void:
	var ui = _get_ui_node()
	if ui:
		ui.update_kill_count(int(value), false)

# 关卡改变
func _on_level_input_value_changed(value: float) -> void:
	if GameState:
		GameState.current_level = int(value)

# 神模式切换
func _on_god_mode_check_toggled(toggled_on: bool) -> void:
	god_mode = toggled_on
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_god_mode"):
		player.set_god_mode(toggled_on)
	print("[GM] 神模式: %s" % ("ON" if toggled_on else "OFF"))

# 游戏速度改变
func _on_speed_slider_value_changed(value: float) -> void:
	Engine.time_scale = value
	_update_speed_label()
	print("[GM] 游戏速度: %.1fx" % value)

# 传送到下一关
func _on_next_level_button_pressed() -> void:
	if GameState:
		var next_level = GameState.current_level + 1
		var level_path = "res://scenes/levels/lv%d.tscn" % next_level
		if ResourceLoader.exists(level_path):
			GameState.current_level = next_level
			get_tree().change_scene_to_file(level_path)
			print("[GM] 传送到关卡: %d" % next_level)
		else:
			print("[GM] 关卡不存在: %s" % level_path)

# 重置当前关卡
func _on_reset_level_button_pressed() -> void:
	get_tree().reload_current_scene()
	print("[GM] 重置当前关卡")

# 添加金币按钮
func _on_add_coins_button_pressed() -> void:
	var ui = _get_ui_node()
	if ui:
		ui.add_coin(100)
	print("[GM] 添加100金币")

# 获取UI节点
func _get_ui_node() -> Node:
	var current_scene = get_tree().current_scene
	if current_scene:
		var ui = current_scene.get_node_or_null("UI")
		if ui:
			return ui
	return get_tree().get_first_node_in_group("ui")
