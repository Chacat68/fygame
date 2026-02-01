# 成就通知UI
# 在屏幕上显示成就解锁通知
extends Control

# 通知队列
var notification_queue: Array[Dictionary] = []
var is_showing: bool = false

# UI组件
@onready var notification_panel: PanelContainer = $NotificationPanel
@onready var icon_label: Label = $NotificationPanel/HBoxContainer/IconLabel
@onready var title_label: Label = $NotificationPanel/HBoxContainer/VBoxContainer/TitleLabel
@onready var name_label: Label = $NotificationPanel/HBoxContainer/VBoxContainer/NameLabel
@onready var description_label: Label = $NotificationPanel/HBoxContainer/VBoxContainer/DescriptionLabel

func _ready() -> void:
	notification_panel.visible = false
	
	# 连接成就管理器信号
	var achievement_mgr = get_node_or_null("/root/AchievementManager")
	if achievement_mgr:
		achievement_mgr.achievement_unlocked.connect(_on_achievement_unlocked)

## 成就解锁回调
func _on_achievement_unlocked(_achievement_id: String, achievement_data: Dictionary) -> void:
	notification_queue.append(achievement_data)
	
	if not is_showing:
		_show_next_notification()

## 显示下一个通知
func _show_next_notification() -> void:
	if notification_queue.is_empty():
		is_showing = false
		return
	
	is_showing = true
	var achievement = notification_queue.pop_front()
	
	# 更新显示内容
	if icon_label:
		icon_label.text = "🏆"
	if title_label:
		title_label.text = "成就解锁"
	if name_label:
		name_label.text = achievement.get("name", "")
	if description_label:
		description_label.text = achievement.get("description", "")
	
	# 播放进入动画
	notification_panel.visible = true
	notification_panel.position.y = -100
	notification_panel.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(notification_panel, "position:y", 20, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(notification_panel, "modulate:a", 1.0, 0.3)
	
	# 播放音效
	if AudioManager:
		AudioManager.play_sfx("power_up")
	
	# 等待显示时间
	await get_tree().create_timer(3.0).timeout
	
	# 播放退出动画
	var exit_tween = create_tween()
	exit_tween.tween_property(notification_panel, "position:y", -100, 0.3).set_ease(Tween.EASE_IN)
	exit_tween.parallel().tween_property(notification_panel, "modulate:a", 0.0, 0.3)
	
	await exit_tween.finished
	notification_panel.visible = false
	
	# 显示下一个
	_show_next_notification()

## 手动显示通知
func show_notification(title: String, message: String, icon: String = "🏆") -> void:
	notification_queue.append({
		"name": title,
		"description": message,
		"icon": icon
	})
	
	if not is_showing:
		_show_next_notification()
