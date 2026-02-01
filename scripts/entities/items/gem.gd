# 宝石收集品
# 比金币更稀有的收集品
class_name Gem
extends "res://scripts/entities/items/collectible_base.gd"

@export_group("宝石属性")
@export_enum("Ruby", "Emerald", "Sapphire", "Diamond") var gem_type: int = 0
@export var gem_values: Array[int] = [5, 10, 15, 25]  # 不同宝石的价值

# 宝石颜色
var gem_colors: Array[Color] = [
	Color(1.0, 0.2, 0.2),   # Ruby - 红色
	Color(0.2, 1.0, 0.2),   # Emerald - 绿色
	Color(0.2, 0.2, 1.0),   # Sapphire - 蓝色
	Color(0.9, 0.9, 1.0)    # Diamond - 白色
]

func _ready() -> void:
	# 设置宝石价值
	value = gem_values[gem_type] if gem_type < gem_values.size() else 5
	
	# 启用旋转效果
	rotate_enabled = true
	rotate_speed = 1.5
	
	super._ready()
	
	# 应用宝石颜色
	_apply_gem_color()

func _register_to_manager() -> void:
	var collectible_mgr = get_node_or_null("/root/CollectibleManager")
	if collectible_mgr:
		collectible_mgr.register_collectible(self, collectible_mgr.CollectibleType.GEM)

func _apply_gem_color() -> void:
	var color = gem_colors[gem_type] if gem_type < gem_colors.size() else Color.WHITE
	
	if sprite:
		sprite.modulate = color
	elif animated_sprite:
		animated_sprite.modulate = color

func _apply_collection_effect(_player: Node) -> void:
	# 添加金币
	if GameState:
		GameState.add_coins(value)

func _play_collect_sound() -> void:
	if AudioManager:
		AudioManager.play_sfx("power_up")

func _show_collect_text() -> void:
	if FloatingTextManager:
		var gem_names = ["红宝石", "绿宝石", "蓝宝石", "钻石"]
		var gem_name = gem_names[gem_type] if gem_type < gem_names.size() else "宝石"
		FloatingTextManager.show_text(global_position + Vector2(0, -20), gem_name, gem_colors[gem_type])
		FloatingTextManager.show_coin(global_position + Vector2(0, -35), value)
