# 技能升级界面
# 管理技能升级树的UI显示和交互
class_name SkillUpgradeUI
extends Control

# UI组件引用
@onready var skill_tree_container = $VBoxContainer/SkillTreeContainer
@onready var coin_label = $VBoxContainer/TopPanel/CoinLabel
@onready var close_button = $VBoxContainer/TopPanel/CloseButton
@onready var dash_skill_panel = $VBoxContainer/SkillTreeContainer/DashSkillPanel
@onready var wall_jump_skill_panel = $VBoxContainer/SkillTreeContainer/WallJumpSkillPanel
@onready var slide_skill_panel = $VBoxContainer/SkillTreeContainer/SlideSkillPanel

# 技能管理器引用
var skill_manager: SkillManager

# 信号
signal skill_upgraded(skill_name: String, new_level: int)
signal ui_closed

func _ready():
	# 连接关闭按钮
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# 初始化技能面板
	_setup_skill_panels()

func _setup_skill_panels():
	# 设置冲刺技能面板
	if dash_skill_panel:
		_setup_skill_panel(dash_skill_panel, "dash")
	
	# 设置墙跳技能面板
	if wall_jump_skill_panel:
		_setup_skill_panel(wall_jump_skill_panel, "wall_jump")
	
	# 设置滑铲技能面板
	if slide_skill_panel:
		_setup_skill_panel(slide_skill_panel, "slide")

func _setup_skill_panel(panel: Control, skill_name: String):
	# 获取面板中的组件
	var unlock_button = panel.get_node_or_null("UnlockButton")
	var upgrade_button = panel.get_node_or_null("UpgradeButton")
	var skill_icon = panel.get_node_or_null("SkillIcon")
	var skill_name_label = panel.get_node_or_null("SkillNameLabel")
	var skill_level_label = panel.get_node_or_null("SkillLevelLabel")
	var skill_description = panel.get_node_or_null("SkillDescription")
	var cost_label = panel.get_node_or_null("CostLabel")
	
	# 连接按钮信号
	if unlock_button:
		unlock_button.pressed.connect(_on_unlock_skill.bind(skill_name))
	
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_skill.bind(skill_name))
	
	# 设置技能名称
	if skill_name_label:
		skill_name_label.text = _get_skill_display_name(skill_name)

func set_skill_manager(manager: SkillManager):
	skill_manager = manager
	_update_ui()

func _update_ui():
	if not skill_manager:
		return
	
	# 更新金币显示
	if coin_label:
		coin_label.text = "金币: " + str(skill_manager.get_coins())
	
	# 更新各个技能面板
	_update_skill_panel(dash_skill_panel, "dash")
	_update_skill_panel(wall_jump_skill_panel, "wall_jump")
	_update_skill_panel(slide_skill_panel, "slide")

func _update_skill_panel(panel: Control, skill_name: String):
	if not panel or not skill_manager:
		return
	
	var skill_data = skill_manager.get_skill_data(skill_name)
	if not skill_data:
		return
	
	# 获取面板组件
	var unlock_button = panel.get_node_or_null("UnlockButton")
	var upgrade_button = panel.get_node_or_null("UpgradeButton")
	var skill_level_label = panel.get_node_or_null("SkillLevelLabel")
	var skill_description = panel.get_node_or_null("SkillDescription")
	var cost_label = panel.get_node_or_null("CostLabel")
	var skill_icon = panel.get_node_or_null("SkillIcon")
	
	# 更新技能等级显示
	if skill_level_label:
		if skill_data.is_unlocked:
			skill_level_label.text = "等级: " + str(skill_data.level) + "/" + str(skill_data.max_level)
		else:
			skill_level_label.text = "未解锁"
	
	# 更新技能描述
	if skill_description:
		skill_description.text = _get_skill_description(skill_name, skill_data.level)
	
	# 更新按钮状态
	if not skill_data.is_unlocked:
		# 技能未解锁
		if unlock_button:
			unlock_button.visible = true
			unlock_button.disabled = not skill_manager.can_unlock_skill(skill_name)
		if upgrade_button:
			upgrade_button.visible = false
		if cost_label:
			cost_label.text = "解锁费用: " + str(skill_data.unlock_cost)
	else:
		# 技能已解锁
		if unlock_button:
			unlock_button.visible = false
		if upgrade_button:
			upgrade_button.visible = true
			upgrade_button.disabled = not skill_manager.can_upgrade_skill(skill_name)
		if cost_label:
			if skill_data.level < skill_data.max_level:
				cost_label.text = "升级费用: " + str(skill_manager.get_upgrade_cost(skill_name))
			else:
				cost_label.text = "已满级"
	
	# 更新技能图标状态
	if skill_icon:
		if skill_data.is_unlocked:
			skill_icon.modulate = Color.WHITE
		else:
			skill_icon.modulate = Color.GRAY

func _get_skill_display_name(skill_name: String) -> String:
	match skill_name:
		"dash":
			return "冲刺"
		"wall_jump":
			return "墙跳"
		"slide":
			return "滑铲"
		_:
			return skill_name

func _get_skill_description(skill_name: String, level: int) -> String:
	match skill_name:
		"dash":
			match level:
				0:
					return "快速向前冲刺，可穿越敌人"
				1:
					return "基础冲刺：距离150，冷却3秒"
				2:
					return "增强冲刺：距离200，冷却2.5秒"
				3:
					return "完美冲刺：距离250，冷却2秒，冲刺时无敌"
				_:
					return "冲刺技能"
		"wall_jump":
			match level:
				0:
					return "贴墙滑行并可以进行墙跳"
				1:
					return "基础墙跳：可连续墙跳2次"
				2:
					return "增强墙跳：可连续墙跳3次，墙跳力度增强"
				3:
					return "完美墙跳：可连续墙跳4次，墙跳恢复空中跳跃"
				_:
					return "墙跳技能"
		"slide":
			match level:
				0:
					return "滑铲攻击敌人并快速移动"
				1:
					return "基础滑铲：伤害20，持续0.8秒"
				2:
					return "增强滑铲：伤害30，持续1.0秒，速度更快"
				3:
					return "完美滑铲：伤害40，持续1.2秒，可跳跃取消"
				_:
					return "滑铲技能"
		_:
			return "未知技能"

func _on_unlock_skill(skill_name: String):
	if skill_manager and skill_manager.unlock_skill(skill_name):
		_update_ui()
		skill_upgraded.emit(skill_name, 1)
		# 播放解锁音效
		AudioManager.play_sfx("power_up")

func _on_upgrade_skill(skill_name: String):
	if skill_manager and skill_manager.upgrade_skill(skill_name):
		var new_level = skill_manager.get_skill_level(skill_name)
		_update_ui()
		skill_upgraded.emit(skill_name, new_level)
		# 播放升级音效
		AudioManager.play_sfx("power_up")

func _on_close_button_pressed():
	ui_closed.emit()
	hide()

func show_ui():
	show()
	_update_ui()

func hide_ui():
	hide()

# 处理输入
func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()