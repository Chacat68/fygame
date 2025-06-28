@tool
extends EditorInspectorPlugin

# 传送配置检查器插件
# 为传送配置资源提供自定义检查器界面

class_name TeleportConfigInspector

func _can_handle(object):
	# 检查是否可以处理传送配置对象
	return object is TeleportConfig

func _parse_begin(object):
	# 开始解析对象时调用
	if object is TeleportConfig:
		# 添加自定义UI元素
		var config = object as TeleportConfig
		_add_teleport_config_ui(config)

func _add_teleport_config_ui(config: TeleportConfig):
	# 添加传送配置的自定义UI
	var container = VBoxContainer.new()
	
	# 添加标题
	var title = Label.new()
	title.text = "传送配置设置"
	title.add_theme_font_size_override("font_size", 16)
	container.add_child(title)
	
	# 添加分隔线
	var separator = HSeparator.new()
	container.add_child(separator)
	
	# 添加配置说明
	var description = Label.new()
	description.text = "配置传送点的位置、目标和触发条件"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(description)
	
	add_custom_control(container)

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	# 解析属性时调用，可以自定义属性显示
	return false  # 返回false表示使用默认处理