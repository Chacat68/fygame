# 关卡终点
# 玩家到达此处即可完成关卡
class_name LevelGoal
extends Area2D

# 信号
signal level_completed(goal: Node)

# 导出变量
@export var next_level_id: int = 0  # 下一关ID（0表示返回关卡选择）
@export var auto_complete: bool = true  # 是否自动触发完成
@export var show_completion_screen: bool = true  # 是否显示完成界面

# 组件引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var particles: GPUParticles2D = $Particles if has_node("Particles") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# 关卡计时器引用
var level_timer: LevelTimer

# 完成状态
var is_completed: bool = false

func _ready() -> void:
	add_to_group("level_goal")
	body_entered.connect(_on_body_entered)
	
	# 查找或创建关卡计时器
	level_timer = get_tree().get_first_node_in_group("level_timer")
	if not level_timer:
		level_timer = LevelTimer.new()
		level_timer.add_to_group("level_timer")
		get_tree().current_scene.add_child(level_timer)
		
		# 获取当前关卡ID
		var scene_name = get_tree().current_scene.name
		var level_id = 1
		if scene_name.begins_with("lv"):
			level_id = int(scene_name.substr(2))
		
		level_timer.start_timer(level_id)
	
	_play_idle_animation()

## 播放待机动画
func _play_idle_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	
	# 粒子效果
	if particles:
		particles.emitting = true

## 当玩家进入区域
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and auto_complete:
		complete_level(body)

## 完成关卡
func complete_level(player: Node = null) -> void:
	if is_completed:
		return
	
	is_completed = true
	
	# 播放完成动画
	_play_complete_animation()
	
	# 播放音效
	if AudioManager:
		AudioManager.play_sfx("power_up")
	
	# 发射信号
	level_completed.emit(self)
	
	# 计算分数
	var score_data = {}
	if level_timer:
		score_data = level_timer.calculate_score()
	
	# 保存关卡完成数据
	_save_level_completion(score_data)
	
	# 解锁下一关
	_unlock_next_level()
	
	# 显示完成界面
	if show_completion_screen:
		await get_tree().create_timer(1.0).timeout
		_show_completion_screen(score_data)
	else:
		# 直接加载下一关
		await get_tree().create_timer(1.5).timeout
		_load_next_level()

## 播放完成动画
func _play_complete_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("complete"):
		animated_sprite.play("complete")
	
	# 禁用碰撞
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# 缩放动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 发射更多粒子
	if particles:
		particles.amount = particles.amount * 3
		particles.emitting = true

## 保存关卡完成数据
func _save_level_completion(score_data: Dictionary) -> void:
	if not SaveManager or not SaveManager.current_save:
		return
	
	var level_id = str(score_data.get("level_id", 0))
	
	if not SaveManager.current_save.has("completed_levels"):
		SaveManager.current_save.completed_levels = {}
	
	# 只保存更好的成绩
	var existing = SaveManager.current_save.completed_levels.get(level_id, {})
	var new_stars = score_data.get("stars", 0)
	var new_time = score_data.get("elapsed_time", 999999.0)
	
	if new_stars >= existing.get("stars", 0) or new_time < existing.get("best_time", 999999.0):
		SaveManager.current_save.completed_levels[level_id] = {
			"stars": max(new_stars, existing.get("stars", 0)),
			"best_time": min(new_time, existing.get("best_time", 999999.0)),
			"best_score": max(score_data.get("total_score", 0), existing.get("best_score", 0))
		}
		
		SaveManager.save_game()

## 解锁下一关
func _unlock_next_level() -> void:
	if next_level_id <= 0:
		return
	
	if SaveManager and SaveManager.current_save:
		if next_level_id > SaveManager.current_save.max_unlocked_level:
			SaveManager.current_save.max_unlocked_level = next_level_id
			SaveManager.save_game()
	
	# 触发成就
	if AchievementManager:
		var current_level_id = 1
		if level_timer:
			current_level_id = level_timer.level_id
		AchievementManager.update_progress("complete_level", 1, {"level_id": current_level_id})

## 显示完成界面
func _show_completion_screen(score_data: Dictionary) -> void:
	# 加载完成界面场景
	var complete_screen_scene = load("res://scenes/ui/level_complete_screen.tscn")
	if complete_screen_scene:
		var complete_screen = complete_screen_scene.instantiate()
		get_tree().current_scene.add_child(complete_screen)
		complete_screen.show_completion(score_data, next_level_id)

## 加载下一关
func _load_next_level() -> void:
	if next_level_id > 0:
		var scene_path = "res://scenes/levels/lv%d.tscn" % next_level_id
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			_return_to_level_select()
	else:
		_return_to_level_select()

## 返回关卡选择
func _return_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select_screen.tscn")
