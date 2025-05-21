extends StaticBody2D

# 平台被攻击时的处理
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 检查玩家是否在攻击范围内
		var player = get_tree().get_first_node_in_group("player")
		if player and player.position.distance_to(position) < 100:  # 攻击范围100像素
			take_damage(20)  # 每次攻击造成20点伤害

# 受到伤害
func take_damage(amount):
	var current_health = get_meta("health")
	current_health -= amount
	
	# 更新血量
	set_meta("health", current_health)
	
	# 计算透明度
	var alpha = float(current_health) / get_meta("max_health")
	
	# 创建淡出动画
	var tween = get_node("Tween")
	tween.interpolate_property($Sprite2D, "modulate:a",
		$Sprite2D.modulate.a, alpha, 0.2,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
	# 如果血量为0，销毁平台
	if current_health <= 0:
		queue_free() 