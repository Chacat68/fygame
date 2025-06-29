extends Node

# 传送门调试脚本
# 用于检查传送门的显示状态

func _ready():
	# 延迟检查，确保所有节点都已初始化
	await get_tree().process_frame
	check_portal_status()

func check_portal_status():
	print("=== 传送门调试信息 ===")
	
	# 查找所有传送门
	var portals = get_tree().get_nodes_in_group("portal")
	print("找到传送门数量: ", portals.size())
	
	for i in range(portals.size()):
		var portal = portals[i]
		print("\n传送门 ", i + 1, ":")
		print("  位置: ", portal.global_position)
		print("  是否激活: ", portal.is_active)
		print("  是否可见: ", portal.visible)
		
		# 检查传送门精灵
		var sprite = portal.get_node_or_null("PortalSprite")
		if sprite:
			print("  精灵存在: true")
			print("  精灵可见: ", sprite.visible)
			print("  精灵透明度: ", sprite.modulate)
			print("  精灵纹理: ", sprite.texture != null)
		else:
			print("  精灵存在: false")
		
		# 检查粒子系统
		var particle_system = portal.get_node_or_null("ParticleSystem")
		if particle_system:
			print("  粒子系统存在: true")
			var particles = particle_system.get_children()
			print("  粒子数量: ", particles.size())
			for particle in particles:
				if particle is CPUParticles2D:
					print("    ", particle.name, " 发射中: ", particle.emitting)
		else:
			print("  粒子系统存在: false")
		
		# 检查传送门信息
		if portal.has_method("get_portal_info"):
			var info = portal.get_portal_info()
			print("  传送门信息: ", info)
	
	print("=== 调试信息结束 ===")