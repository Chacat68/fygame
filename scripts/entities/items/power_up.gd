# 能力拾取物
# 玩家拾取后获得临时或永久能力提升
class_name PowerUp
extends CollectibleBase

# 能力类型枚举
enum PowerUpType {
	SPEED_BOOST,      # 速度提升
	JUMP_BOOST,       # 跳跃提升
	INVINCIBILITY,    # 无敌
	DOUBLE_COINS,     # 双倍金币
	EXTRA_JUMP,       # 额外跳跃次数
	MAGNET,           # 金币磁铁
	HEALTH_REGEN      # 生命恢复
}

@export_group("能力属性")
@export var power_type: PowerUpType = PowerUpType.SPEED_BOOST
@export var duration: float = 10.0  # 持续时间（永久效果此值无效）
@export var strength: float = 1.5   # 效果强度
@export var is_permanent: bool = false  # 是否永久

# 能力颜色
var power_colors: Dictionary = {
	PowerUpType.SPEED_BOOST: Color(0.3, 0.6, 1.0),     # 蓝色
	PowerUpType.JUMP_BOOST: Color(0.3, 1.0, 0.3),      # 绿色
	PowerUpType.INVINCIBILITY: Color(1.0, 0.85, 0.0),  # 金色
	PowerUpType.DOUBLE_COINS: Color(1.0, 0.6, 0.0),    # 橙色
	PowerUpType.EXTRA_JUMP: Color(0.5, 1.0, 0.8),      # 青色
	PowerUpType.MAGNET: Color(0.8, 0.0, 0.8),          # 紫色
	PowerUpType.HEALTH_REGEN: Color(1.0, 0.3, 0.3)     # 红色
}

func _ready() -> void:
	bob_speed = 2.5
	bob_amplitude = 5.0
	rotate_enabled = true
	rotate_speed = 2.0
	
	super._ready()
	
	# 应用能力颜色
	_apply_power_color()

func _register_to_manager() -> void:
	if CollectibleManager:
		CollectibleManager.register_collectible(self, CollectibleManager.CollectibleType.POWERUP)

func _apply_power_color() -> void:
	var color = power_colors.get(power_type, Color.WHITE)
	
	if sprite:
		sprite.modulate = color
	elif animated_sprite:
		animated_sprite.modulate = color

func _apply_collection_effect(player: Node) -> void:
	if not player:
		return
	
	match power_type:
		PowerUpType.SPEED_BOOST:
			_apply_speed_boost(player)
		PowerUpType.JUMP_BOOST:
			_apply_jump_boost(player)
		PowerUpType.INVINCIBILITY:
			_apply_invincibility(player)
		PowerUpType.DOUBLE_COINS:
			_apply_double_coins()
		PowerUpType.EXTRA_JUMP:
			_apply_extra_jump(player)
		PowerUpType.MAGNET:
			_apply_magnet()
		PowerUpType.HEALTH_REGEN:
			_apply_health_regen(player)

## 速度提升
func _apply_speed_boost(player: Node) -> void:
	if ItemManager:
		ItemManager._add_timed_effect("speed_boost", duration, strength)
	
	# 临时增加玩家速度（如果没有使用ItemManager）
	if "SPEED" in player:
		var original_speed = player.SPEED
		player.SPEED *= strength
		
		if not is_permanent:
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(player):
				player.SPEED = original_speed

## 跳跃提升
func _apply_jump_boost(player: Node) -> void:
	if ItemManager:
		ItemManager._add_timed_effect("jump_boost", duration, strength)
	
	if "JUMP_VELOCITY" in player:
		var original_jump = player.JUMP_VELOCITY
		player.JUMP_VELOCITY *= strength
		
		if not is_permanent:
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(player):
				player.JUMP_VELOCITY = original_jump

## 无敌
func _apply_invincibility(player: Node) -> void:
	if ItemManager:
		ItemManager._add_timed_effect("invincibility", duration, 1.0)
	
	if player.has_method("start_invincibility"):
		player.start_invincibility(duration)

## 双倍金币
func _apply_double_coins() -> void:
	if ItemManager:
		ItemManager._add_timed_effect("double_coins", duration, 2.0)

## 额外跳跃
func _apply_extra_jump(player: Node) -> void:
	if "MAX_JUMPS" in player:
		player.MAX_JUMPS += 1
		
		if not is_permanent:
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(player):
				player.MAX_JUMPS = max(1, player.MAX_JUMPS - 1)

## 金币磁铁
func _apply_magnet() -> void:
	# 使用道具系统的磁铁效果
	if ItemManager:
		ItemManager.add_item("coin_magnet", 1)

## 生命恢复
func _apply_health_regen(player: Node) -> void:
	if "current_health" in player and "MAX_HEALTH" in player:
		# 持续恢复生命
		var total_heal = int(strength * 10)  # 总共恢复的生命
		var heal_per_tick = 1
		var tick_count = total_heal / heal_per_tick
		var tick_interval = duration / tick_count
		
		for i in range(tick_count):
			if is_instance_valid(player) and player.current_health < player.MAX_HEALTH:
				player.current_health = min(player.current_health + heal_per_tick, player.MAX_HEALTH)
				if player.has_signal("health_changed"):
					player.health_changed.emit(player.current_health)
			await get_tree().create_timer(tick_interval).timeout

func _play_collect_sound() -> void:
	if AudioManager:
		AudioManager.play_sfx("power_up")

func _show_collect_text() -> void:
	if FloatingTextManager:
		var power_names = {
			PowerUpType.SPEED_BOOST: "速度提升!",
			PowerUpType.JUMP_BOOST: "跳跃提升!",
			PowerUpType.INVINCIBILITY: "无敌!",
			PowerUpType.DOUBLE_COINS: "双倍金币!",
			PowerUpType.EXTRA_JUMP: "额外跳跃!",
			PowerUpType.MAGNET: "金币磁铁!",
			PowerUpType.HEALTH_REGEN: "生命恢复!"
		}
		var text = power_names.get(power_type, "能力提升!")
		var color = power_colors.get(power_type, Color.WHITE)
		FloatingTextManager.show_text(global_position + Vector2(0, -30), text, color)
