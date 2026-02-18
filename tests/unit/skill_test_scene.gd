# 技能系统测试场景
# 用于测试和演示技能系统的各项功能
class_name SkillTestScene
extends Node2D

# UI组件引用
@onready var skill_ui = $UI/SkillUpgradeUI
@onready var debug_panel = $UI/DebugPanel
@onready var player = $Player

# 调试标签
@onready var dash_cooldown_label = $UI/DebugPanel/VBoxContainer/DashCooldownLabel
@onready var wall_jump_cooldown_label = $UI/DebugPanel/VBoxContainer/WallJumpCooldownLabel
@onready var slide_cooldown_label = $UI/DebugPanel/VBoxContainer/SlideCooldownLabel
@onready var player_state_label = $UI/DebugPanel/VBoxContainer/PlayerStateLabel
@onready var coins_label = $UI/DebugPanel/VBoxContainer/CoinsLabel

func _ready():
	# 设置技能UI
	if skill_ui and player:
		skill_ui.set_skill_manager(player.get_skill_manager())
		skill_ui.skill_upgraded.connect(_on_skill_upgraded)
		skill_ui.ui_closed.connect(_on_skill_ui_closed)
	
	# 初始隐藏技能UI
	if skill_ui:
		skill_ui.hide()
	
	# 给玩家一些初始金币用于测试
	if player and player.get_skill_manager():
		player.get_skill_manager().add_coins(1000)

func _process(_delta):
	_update_debug_info()

func _update_debug_info():
	if not player or not player.get_skill_manager():
		return
	
	var skill_manager = player.get_skill_manager()
	
	# 更新冷却时间显示
	if dash_cooldown_label:
		var dash_cooldown = skill_manager.get_skill_cooldown("dash")
		dash_cooldown_label.text = "冲刺冷却: " + ("%.1f" % dash_cooldown if dash_cooldown > 0 else "就绪")
	
	if wall_jump_cooldown_label:
		var wall_jump_cooldown = skill_manager.get_skill_cooldown("wall_jump")
		wall_jump_cooldown_label.text = "墙跳冷却: " + ("%.1f" % wall_jump_cooldown if wall_jump_cooldown > 0 else "就绪")
	
	if slide_cooldown_label:
		var slide_cooldown = skill_manager.get_skill_cooldown("slide")
		slide_cooldown_label.text = "滑铲冷却: " + ("%.1f" % slide_cooldown if slide_cooldown > 0 else "就绪")
	
	# 更新玩家状态显示
	if player_state_label and player.current_state:
		player_state_label.text = "玩家状态: " + player.current_state.get_state_name()
	
	# 更新金币显示
	if coins_label:
		coins_label.text = "金币: " + str(skill_manager.get_coins())

func _input(event):
	# 按Tab键打开/关闭技能升级界面
	if event.is_action_pressed("ui_accept") and skill_ui:  # 使用回车键作为测试
		if skill_ui.visible:
			skill_ui.hide_ui()
		else:
			skill_ui.show_ui()
	
	# 调试快捷键
	if event.is_action_pressed("ui_select"):  # 空格键
		_add_test_coins()

func _add_test_coins():
	# 添加测试金币
	if player and player.get_skill_manager():
		player.get_skill_manager().add_coins(500)
		print("添加了500金币用于测试")

func _on_skill_upgraded(skill_name: String, new_level: int):
	print("技能升级: ", skill_name, " 新等级: ", new_level)

func _on_skill_ui_closed():
	print("技能界面已关闭")