# 虚空守卫 - 终章 Boss
# 巨型紫色史莱姆，3 阶段战斗
extends CharacterBody2D

class_name VoidGuardian

signal boss_defeated
signal phase_changed(phase: int)
signal health_changed(current: float, maximum: float)

# ── 配置 ──────────────────────────────────────────────

@export var max_health: float = 300.0
@export var contact_damage: int = 20
@export var move_speed: float = 60.0
@export var jump_force: float = -350.0
@export var gravity_scale: float = 1.0

# 阶段阈值（按血量百分比）
const PHASE_2_THRESHOLD := 0.6 # 60% 血量进入第 2 阶段
const PHASE_3_THRESHOLD := 0.3 # 30% 血量进入第 3 阶段

# ── 状态 ──────────────────────────────────────────────

var health: float
var current_phase: int = 1
var is_defeated: bool = false
var target: Node2D = null # 玩家引用

# 内部计时器
var _action_timer: float = 0.0
var _summon_timer: float = 0.0
var _is_jumping: bool = false
var _jump_cooldown: float = 0.0
var _direction: int = 1
var _hit_flash_timer: float = 0.0

# 重力
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

# 子节点
var _sprite: AnimatedSprite2D
var _collision: CollisionShape2D
var _damage_area: Area2D
var _health_bar: ProgressBar
var _phase_label: Label

func _ready():
	health = max_health
	_build_visual()
	_find_player()
	add_to_group("boss")
	add_to_group("enemies")

func _physics_process(delta: float):
	if is_defeated:
		return

	# 重力
	if not is_on_floor():
		velocity.y += _gravity * gravity_scale * delta
	else:
		_is_jumping = false

	# 受击闪烁
	if _hit_flash_timer > 0:
		_hit_flash_timer -= delta
		_sprite.modulate = Color(1, 0.3, 0.3) if fmod(_hit_flash_timer, 0.1) > 0.05 else Color.WHITE
		if _hit_flash_timer <= 0:
			_sprite.modulate = Color.WHITE

	# 寻找玩家
	if not is_instance_valid(target):
		_find_player()
		return

	# 行动计时
	_action_timer += delta
	_jump_cooldown -= delta
	_summon_timer += delta

	# 朝玩家移动
	_direction = 1 if target.global_position.x > global_position.x else -1
	_sprite.flip_h = _direction < 0

	# 按阶段行为
	match current_phase:
		1:
			_phase_1_behavior(delta)
		2:
			_phase_2_behavior(delta)
		3:
			_phase_3_behavior(delta)

	move_and_slide()

	# 更新血条
	_update_health_bar()

# ── 阶段行为 ──────────────────────────────────────────

func _phase_1_behavior(delta: float):
	# 阶段 1：缓慢追踪 + 偶尔跳跃
	var speed = move_speed
	velocity.x = _direction * speed

	if _jump_cooldown <= 0 and is_on_floor() and _action_timer > 2.0:
		velocity.y = jump_force
		_is_jumping = true
		_jump_cooldown = 3.0
		_action_timer = 0.0

func _phase_2_behavior(delta: float):
	# 阶段 2：加速 + 召唤小史莱姆
	var speed = move_speed * 1.5
	velocity.x = _direction * speed

	# 跳跃更频繁
	if _jump_cooldown <= 0 and is_on_floor() and _action_timer > 1.5:
		velocity.y = jump_force * 1.2
		_is_jumping = true
		_jump_cooldown = 2.0
		_action_timer = 0.0

	# 召唤小史莱姆
	if _summon_timer > 6.0:
		_summon_minions(2)
		_summon_timer = 0.0

func _phase_3_behavior(delta: float):
	# 阶段 3：狂暴！高速 + 大跳 + 频繁召唤
	var speed = move_speed * 2.0
	velocity.x = _direction * speed

	# 疯狂跳跃
	if _jump_cooldown <= 0 and is_on_floor() and _action_timer > 1.0:
		velocity.y = jump_force * 1.5
		_is_jumping = true
		_jump_cooldown = 1.5
		_action_timer = 0.0

	# 频繁召唤
	if _summon_timer > 4.0:
		_summon_minions(3)
		_summon_timer = 0.0

# ── 伤害 ─────────────────────────────────────────────

## 受到伤害（由外部调用，如玩家踩踏）
func take_damage(amount: float):
	if is_defeated:
		return

	health -= amount
	_hit_flash_timer = 0.3
	health_changed.emit(health, max_health)

	# 检查阶段切换
	var health_ratio = health / max_health

	if current_phase == 1 and health_ratio <= PHASE_2_THRESHOLD:
		_enter_phase(2)
	elif current_phase == 2 and health_ratio <= PHASE_3_THRESHOLD:
		_enter_phase(3)

	if health <= 0:
		_defeat()

func _enter_phase(phase: int):
	current_phase = phase
	phase_changed.emit(phase)

	# 阶段切换视觉反馈
	match phase:
		2:
			_sprite.modulate = Color(0.8, 0.3, 0.8) # 更紫
			if _phase_label:
				_phase_label.text = "虚空守卫 — 觉醒"
			_shake_effect()
		3:
			_sprite.modulate = Color(0.6, 0.1, 0.6) # 深紫
			if _phase_label:
				_phase_label.text = "虚空守卫 — 狂暴！"
			scale = Vector2(1.3, 1.3) # 增大
			_shake_effect()

func _defeat():
	is_defeated = true
	velocity = Vector2.ZERO

	if _phase_label:
		_phase_label.text = "虚空守卫 — 解放"

	# 死亡动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func():
		boss_defeated.emit()
		queue_free()
	)

# ── 召唤小史莱姆 ──────────────────────────────────────

func _summon_minions(count: int):
	var slime_scene = load("res://scenes/entities/slime.tscn")
	if not slime_scene:
		return

	for i in range(count):
		var slime = slime_scene.instantiate()
		slime.position = global_position + Vector2(randf_range(-50, 50), -20)
		# 设置为紫色
		if slime.has_method("set") and "is_purple" in slime:
			slime.is_purple = true
		get_parent().add_child(slime)

# ── 工具方法 ──────────────────────────────────────────

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _shake_effect():
	var original_pos = position
	var tween = create_tween()
	for i in range(6):
		tween.tween_property(self, "position", original_pos + Vector2(randf_range(-5, 5), randf_range(-3, 3)), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

func _update_health_bar():
	if _health_bar:
		_health_bar.value = (health / max_health) * 100.0

# ── 视觉构建 ──────────────────────────────────────────

func _build_visual():
	# 碰撞形状（大型）
	_collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 40)
	_collision.shape = shape
	_collision.position = Vector2(0, -20)
	add_child(_collision)

	# 动画精灵（使用紫色史莱姆放大）
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	var sprite_texture = load("res://assets/sprites/slime_purple.png")
	if sprite_texture:
		var frames = SpriteFrames.new()
		frames.add_animation("idle")
		frames.add_frame("idle", sprite_texture)
		_sprite.sprite_frames = frames
		_sprite.play("idle")
	_sprite.scale = Vector2(3, 3) # 3 倍大小
	_sprite.position = Vector2(0, -20)
	add_child(_sprite)

	# 伤害区域
	_damage_area = Area2D.new()
	_damage_area.name = "DamageArea"
	var area_collision = CollisionShape2D.new()
	var area_shape = RectangleShape2D.new()
	area_shape.size = Vector2(52, 44)
	area_collision.shape = area_shape
	area_collision.position = Vector2(0, -20)
	_damage_area.add_child(area_collision)
	_damage_area.body_entered.connect(_on_body_entered)
	add_child(_damage_area)

	# 血条（头顶）
	_health_bar = ProgressBar.new()
	_health_bar.name = "HealthBar"
	_health_bar.custom_minimum_size = Vector2(60, 6)
	_health_bar.position = Vector2(-30, -55)
	_health_bar.value = 100.0
	_health_bar.show_percentage = false

	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.5, 0.1, 0.5)
	_health_bar.add_theme_stylebox_override("fill", bar_style)

	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.15, 0.15)
	_health_bar.add_theme_stylebox_override("background", bar_bg)
	add_child(_health_bar)

	# 名字标签
	_phase_label = Label.new()
	_phase_label.name = "PhaseLabel"
	_phase_label.text = "虚空守卫"
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.position = Vector2(-40, -68)
	_phase_label.add_theme_font_size_override("font_size", 10)
	_phase_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.9))
	add_child(_phase_label)

func _on_body_entered(body: Node2D):
	if is_defeated:
		return
	# 玩家踩踏检测：如果玩家从上方落下，造成伤害给 Boss
	if body.is_in_group("player"):
		if body.velocity.y > 0 and body.global_position.y < global_position.y - 15:
			take_damage(30)
			# 弹起玩家
			body.velocity.y = -300
		else:
			# Boss 对玩家造成伤害
			if body.has_method("take_damage"):
				body.take_damage(contact_damage)
