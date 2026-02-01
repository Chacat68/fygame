# 心形收集品
# 恢复玩家生命值
class_name Heart
extends CollectibleBase

@export_group("心形属性")
@export var heal_amount: int = 25  # 恢复血量
@export var full_heal: bool = false  # 是否完全恢复

func _ready() -> void:
	value = heal_amount
	bob_speed = 1.5
	bob_amplitude = 3.0
	
	super._ready()
	
	# 设置红色调
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.3)
	elif animated_sprite:
		animated_sprite.modulate = Color(1.0, 0.3, 0.3)

func _register_to_manager() -> void:
	if CollectibleManager:
		CollectibleManager.register_collectible(self, CollectibleManager.CollectibleType.HEART)

func _apply_collection_effect(player: Node) -> void:
	if not player:
		return
	
	# 恢复生命
	if player.has_method("heal"):
		player.heal(heal_amount if not full_heal else player.MAX_HEALTH)
	elif "current_health" in player and "MAX_HEALTH" in player:
		var heal = player.MAX_HEALTH if full_heal else heal_amount
		player.current_health = min(player.current_health + heal, player.MAX_HEALTH)
		
		if player.has_signal("health_changed"):
			player.health_changed.emit(player.current_health)

func _play_collect_sound() -> void:
	if AudioManager:
		AudioManager.play_sfx("power_up")

func _show_collect_text() -> void:
	if FloatingTextManager:
		var text = "满血恢复!" if full_heal else "+%d HP" % heal_amount
		FloatingTextManager.show_text(global_position + Vector2(0, -20), text, Color(0.2, 1.0, 0.2))
