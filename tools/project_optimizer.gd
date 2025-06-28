@tool
extends EditorScript

# 项目优化工具
# 用于验证配置、检查资源完整性和优化项目结构

const OPTIMIZATION_REPORT_PATH = "res://optimization_report.txt"

var report_lines: Array[String] = []
var issues_found: int = 0
var optimizations_applied: int = 0

func _run():
	print("开始项目优化检查...")
	report_lines.clear()
	issues_found = 0
	optimizations_applied = 0
	
	_add_report_header()
	_check_project_structure()
	_validate_resource_paths()
	_check_script_dependencies()
	_analyze_performance_bottlenecks()
	_suggest_optimizations()
	_generate_report()
	
	print("优化检查完成！")
	print("发现问题: %d" % issues_found)
	print("应用优化: %d" % optimizations_applied)
	print("报告已保存到: %s" % OPTIMIZATION_REPORT_PATH)

func _add_report_header():
	report_lines.append("# Godot项目优化报告")
	report_lines.append("生成时间: %s" % Time.get_datetime_string_from_system())
	report_lines.append("项目路径: %s" % ProjectSettings.globalize_path("res://"))
	report_lines.append("")

func _check_project_structure():
	report_lines.append("## 项目结构检查")
	report_lines.append("")
	
	# 检查必要的目录结构
	var required_dirs = [
		"res://scripts/",
		"res://scenes/",
		"res://assets/",
		"res://tests/",
		"res://tools/"
	]
	
	for dir_path in required_dirs:
		if DirAccess.dir_exists_absolute(dir_path):
			report_lines.append("✓ 目录存在: %s" % dir_path)
		else:
			report_lines.append("✗ 缺少目录: %s" % dir_path)
			issues_found += 1
	
	# 检查脚本组织
	_check_script_organization()
	
	report_lines.append("")

func _check_script_organization():
	report_lines.append("### 脚本组织检查")
	
	var script_dirs = [
		"res://scripts/managers/",
		"res://scripts/entities/",
		"res://scripts/ui/",
		"res://scripts/states/"
	]
	
	for dir_path in script_dirs:
		if DirAccess.dir_exists_absolute(dir_path):
			var file_count = _count_files_in_directory(dir_path, ".gd")
			report_lines.append("✓ %s (%d个脚本)" % [dir_path, file_count])
		else:
			report_lines.append("✗ 建议创建目录: %s" % dir_path)

func _count_files_in_directory(dir_path: String, extension: String) -> int:
	var count = 0
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(extension):
				count += 1
			file_name = dir.get_next()
	return count

func _validate_resource_paths():
	report_lines.append("## 资源路径验证")
	report_lines.append("")
	
	# 检查ResourceManager中的资源路径
	var resource_manager_path = "res://scripts/managers/resource_manager.gd"
	if FileAccess.file_exists(resource_manager_path):
		_validate_resource_manager_paths()
	else:
		report_lines.append("✗ ResourceManager脚本不存在: %s" % resource_manager_path)
		issues_found += 1
	
	report_lines.append("")

func _validate_resource_manager_paths():
	report_lines.append("### ResourceManager资源路径检查")
	
	# 定义需要检查的资源路径
	var resource_paths = {
		"音效": [
			"res://assets/sounds/jump.wav",
			"res://assets/sounds/hurt.wav",
			"res://assets/sounds/coin.wav",
			"res://assets/sounds/power_up.wav",
			"res://assets/sounds/explosion.wav",
			"res://assets/sounds/tap.wav"
		],
		"音乐": [
			"res://assets/music/time_for_adventure.mp3"
		],
		"精灵": [
			"res://assets/sprites/knight.png",
			"res://assets/sprites/coin.png",
			"res://assets/sprites/slime_green.png",
			"res://assets/sprites/slime_purple.png",
			"res://assets/sprites/platforms.png",
			"res://assets/sprites/world_tileset.png",
			"res://assets/sprites/fruit.png",
			"res://assets/sprites/coin_icon.png"
		],
		"场景": [
			"res://scenes/entities/coin.tscn",
			"res://scenes/entities/slime.tscn",
			"res://scenes/entities/platform.tscn",
			"res://scenes/managers/floating_text.tscn"
		]
	}
	
	for category in resource_paths:
		report_lines.append("#### %s资源" % category)
		for path in resource_paths[category]:
			if ResourceLoader.exists(path):
				report_lines.append("✓ %s" % path)
			else:
				report_lines.append("✗ 缺少资源: %s" % path)
				issues_found += 1

func _check_script_dependencies():
	report_lines.append("## 脚本依赖检查")
	report_lines.append("")
	
	# 检查关键脚本的存在性
	var critical_scripts = [
		"res://scripts/managers/level_manager.gd",
		"res://scripts/managers/resource_manager.gd",
		"res://scripts/managers/game_config.gd",
		"res://scripts/managers/level_config.gd",
		"res://scripts/entities/player.gd",
		"res://scripts/states/player_state.gd"
	]
	
	for script_path in critical_scripts:
		if FileAccess.file_exists(script_path):
			report_lines.append("✓ %s" % script_path)
			_analyze_script_quality(script_path)
		else:
			report_lines.append("✗ 缺少关键脚本: %s" % script_path)
			issues_found += 1
	
	report_lines.append("")

func _analyze_script_quality(script_path: String):
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var line_count = lines.size()
	var comment_lines = 0
	var empty_lines = 0
	
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.begins_with("#"):
			comment_lines += 1
		elif trimmed.is_empty():
			empty_lines += 1
	
	var code_lines = line_count - comment_lines - empty_lines
	var comment_ratio = float(comment_lines) / float(code_lines) if code_lines > 0 else 0
	
	# 分析代码质量
	if comment_ratio < 0.1:
		report_lines.append("  ⚠ 注释不足 (%.1f%%)" % (comment_ratio * 100))
		issues_found += 1
	
	if code_lines > 300:
		report_lines.append("  ⚠ 文件过大 (%d行代码)" % code_lines)
		issues_found += 1

func _analyze_performance_bottlenecks():
	report_lines.append("## 性能瓶颈分析")
	report_lines.append("")
	
	# 检查可能的性能问题
	_check_for_performance_issues()
	
	report_lines.append("")

func _check_for_performance_issues():
	report_lines.append("### 潜在性能问题")
	
	# 检查大型纹理
	_check_large_textures()
	
	# 检查音频文件大小
	_check_audio_file_sizes()
	
	# 检查场景复杂度
	_check_scene_complexity()

func _check_large_textures():
	report_lines.append("#### 纹理大小检查")
	
	var texture_dir = "res://assets/sprites/"
	if DirAccess.dir_exists_absolute(texture_dir):
		var dir = DirAccess.open(texture_dir)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
					var file_path = texture_dir + file_name
					var file_size = FileAccess.get_file_as_bytes(file_path).size()
					if file_size > 1024 * 1024:  # 1MB
						report_lines.append("⚠ 大型纹理: %s (%.2f MB)" % [file_name, file_size / (1024.0 * 1024.0)])
						issues_found += 1
				file_name = dir.get_next()

func _check_audio_file_sizes():
	report_lines.append("#### 音频文件大小检查")
	
	var audio_dirs = ["res://assets/sounds/", "res://assets/music/"]
	for audio_dir in audio_dirs:
		if DirAccess.dir_exists_absolute(audio_dir):
			var dir = DirAccess.open(audio_dir)
			if dir:
				dir.list_dir_begin()
				var file_name = dir.get_next()
				while file_name != "":
					if file_name.ends_with(".wav") or file_name.ends_with(".mp3") or file_name.ends_with(".ogg"):
						var file_path = audio_dir + file_name
						var file_size = FileAccess.get_file_as_bytes(file_path).size()
						if file_size > 5 * 1024 * 1024:  # 5MB
							report_lines.append("⚠ 大型音频文件: %s (%.2f MB)" % [file_name, file_size / (1024.0 * 1024.0)])
							issues_found += 1
					file_name = dir.get_next()

func _check_scene_complexity():
	report_lines.append("#### 场景复杂度检查")
	
	var scenes_dir = "res://scenes/"
	if DirAccess.dir_exists_absolute(scenes_dir):
		_check_scenes_in_directory(scenes_dir)

func _check_scenes_in_directory(dir_path: String):
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = dir_path + file_name
		if dir.current_is_dir():
			_check_scenes_in_directory(full_path + "/")
		elif file_name.ends_with(".tscn"):
			var scene_size = FileAccess.get_file_as_bytes(full_path).size()
			if scene_size > 100 * 1024:  # 100KB
				report_lines.append("⚠ 复杂场景: %s (%.2f KB)" % [file_name, scene_size / 1024.0])
				issues_found += 1
		file_name = dir.get_next()

func _suggest_optimizations():
	report_lines.append("## 优化建议")
	report_lines.append("")
	
	report_lines.append("### 代码优化")
	report_lines.append("- 使用对象池减少内存分配")
	report_lines.append("- 实现LOD系统降低渲染复杂度")
	report_lines.append("- 使用信号替代轮询检查")
	report_lines.append("- 缓存频繁访问的资源")
	report_lines.append("")
	
	report_lines.append("### 资源优化")
	report_lines.append("- 压缩大型纹理")
	report_lines.append("- 使用纹理图集减少绘制调用")
	report_lines.append("- 转换音频为OGG格式")
	report_lines.append("- 移除未使用的资源")
	report_lines.append("")
	
	report_lines.append("### 架构优化")
	report_lines.append("- 实现场景流式加载")
	report_lines.append("- 使用多线程处理重任务")
	report_lines.append("- 添加性能监控系统")
	report_lines.append("- 实现自动化测试")
	report_lines.append("")

func _generate_report():
	var file = FileAccess.open(OPTIMIZATION_REPORT_PATH, FileAccess.WRITE)
	if file:
		for line in report_lines:
			file.store_line(line)
		file.close()
		print("报告已生成: %s" % OPTIMIZATION_REPORT_PATH)
	else:
		print("无法创建报告文件")