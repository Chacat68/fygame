extends Node

# 环境类型枚举
enum EnvironmentType {
	NORMAL = 0,    # 正常环境
	HOT = 1,       # 高温环境
	COLD = 2,      # 低温环境
	TOXIC = 3,     # 有毒环境
	RADIATION = 4  # 辐射环境
}

# 环境数据
var environment_data = {
	"temperature": 20.0,  # 摄氏度
	"oxygen_level": 1.0,  # 氧气浓度（0-1）
	"toxicity": 0.0,      # 毒性水平（0-1）
	"radiation": 0.0,     # 辐射水平（0-1）
	"humidity": 0.5,      # 湿度（0-1）
	"pressure": 1.0,      # 气压（标准大气压）
	"type": EnvironmentType.NORMAL
}

# 环境参数
var temperature_decay_rate = 0.1  # 温度自然衰减率
var oxygen_decay_rate = 0.01      # 氧气自然衰减率
var toxicity_decay_rate = 0.05    # 毒性自然衰减率
var radiation_decay_rate = 0.02   # 辐射自然衰减率

# 环境影响参数
var temperature_effect = {
	"min_safe": 15.0,    # 最低安全温度
	"max_safe": 30.0,    # 最高安全温度
	"min_critical": 5.0, # 最低危险温度
	"max_critical": 40.0 # 最高危险温度
}

var oxygen_effect = {
	"min_safe": 0.8,     # 最低安全氧气浓度
	"max_safe": 1.0,     # 最高安全氧气浓度
	"min_critical": 0.5, # 最低危险氧气浓度
	"max_critical": 1.2  # 最高危险氧气浓度
}

# 信号
signal environment_changed(environment_data)
signal environment_critical(parameter)
signal environment_normal(parameter)

# 预加载资源系统
var resource_system = preload("res://scripts/resource_system.gd").new()

func _ready():
	# 初始化环境系统
	pass

func _process(delta):
	_update_environment(delta)
	_check_environment_effects()

# 更新环境参数
func _update_environment(delta):
	# 更新温度
	var heat_resource = resource_system.get_resource(resource_system.ResourceType.HEAT)
	environment_data.temperature += (heat_resource - 20.0) * delta
	environment_data.temperature = clamp(environment_data.temperature, -50.0, 100.0)
	
	# 更新氧气水平
	var oxygen_resource = resource_system.get_resource(resource_system.ResourceType.OXYGEN)
	var oxygen_max = resource_system.get_resource_max(resource_system.ResourceType.OXYGEN)
	environment_data.oxygen_level = oxygen_resource / oxygen_max
	
	# 更新毒性
	environment_data.toxicity = max(0.0, environment_data.toxicity - toxicity_decay_rate * delta)
	
	# 更新辐射
	environment_data.radiation = max(0.0, environment_data.radiation - radiation_decay_rate * delta)
	
	# 发出环境变化信号
	emit_signal("environment_changed", environment_data)

# 检查环境效果
func _check_environment_effects():
	# 检查温度
	if environment_data.temperature < temperature_effect.min_critical or environment_data.temperature > temperature_effect.max_critical:
		emit_signal("environment_critical", "temperature")
	elif environment_data.temperature < temperature_effect.min_safe or environment_data.temperature > temperature_effect.max_safe:
		emit_signal("environment_critical", "temperature")
	else:
		emit_signal("environment_normal", "temperature")
	
	# 检查氧气
	if environment_data.oxygen_level < oxygen_effect.min_critical or environment_data.oxygen_level > oxygen_effect.max_critical:
		emit_signal("environment_critical", "oxygen")
	elif environment_data.oxygen_level < oxygen_effect.min_safe or environment_data.oxygen_level > oxygen_effect.max_safe:
		emit_signal("environment_critical", "oxygen")
	else:
		emit_signal("environment_normal", "oxygen")
	
	# 检查毒性
	if environment_data.toxicity > 0.8:
		emit_signal("environment_critical", "toxicity")
	elif environment_data.toxicity > 0.5:
		emit_signal("environment_critical", "toxicity")
	else:
		emit_signal("environment_normal", "toxicity")
	
	# 检查辐射
	if environment_data.radiation > 0.8:
		emit_signal("environment_critical", "radiation")
	elif environment_data.radiation > 0.5:
		emit_signal("environment_critical", "radiation")
	else:
		emit_signal("environment_normal", "radiation")

# 获取环境类型
func get_environment_type():
	return environment_data.type

# 设置环境类型
func set_environment_type(type):
	environment_data.type = type
	match type:
		EnvironmentType.HOT:
			environment_data.temperature = 35.0
		EnvironmentType.COLD:
			environment_data.temperature = 5.0
		EnvironmentType.TOXIC:
			environment_data.toxicity = 0.7
		EnvironmentType.RADIATION:
			environment_data.radiation = 0.7

# 获取温度
func get_temperature():
	return environment_data.temperature

# 获取氧气水平
func get_oxygen_level():
	return environment_data.oxygen_level

# 获取毒性水平
func get_toxicity():
	return environment_data.toxicity

# 获取辐射水平
func get_radiation():
	return environment_data.radiation

# 获取湿度
func get_humidity():
	return environment_data.humidity

# 获取气压
func get_pressure():
	return environment_data.pressure

# 添加热量
func add_heat(amount):
	environment_data.temperature += amount
	environment_data.temperature = clamp(environment_data.temperature, -50.0, 100.0)

# 添加毒性
func add_toxicity(amount):
	environment_data.toxicity = clamp(environment_data.toxicity + amount, 0.0, 1.0)

# 添加辐射
func add_radiation(amount):
	environment_data.radiation = clamp(environment_data.radiation + amount, 0.0, 1.0)

# 获取环境状态
func get_environment_status():
	var status = {
		"temperature": "normal",
		"oxygen": "normal",
		"toxicity": "normal",
		"radiation": "normal"
	}
	
	# 检查温度状态
	if environment_data.temperature < temperature_effect.min_critical or environment_data.temperature > temperature_effect.max_critical:
		status.temperature = "critical"
	elif environment_data.temperature < temperature_effect.min_safe or environment_data.temperature > temperature_effect.max_safe:
		status.temperature = "warning"
	
	# 检查氧气状态
	if environment_data.oxygen_level < oxygen_effect.min_critical or environment_data.oxygen_level > oxygen_effect.max_critical:
		status.oxygen = "critical"
	elif environment_data.oxygen_level < oxygen_effect.min_safe or environment_data.oxygen_level > oxygen_effect.max_safe:
		status.oxygen = "warning"
	
	# 检查毒性状态
	if environment_data.toxicity > 0.8:
		status.toxicity = "critical"
	elif environment_data.toxicity > 0.5:
		status.toxicity = "warning"
	
	# 检查辐射状态
	if environment_data.radiation > 0.8:
		status.radiation = "critical"
	elif environment_data.radiation > 0.5:
		status.radiation = "warning"
	
	return status

# 获取环境效率修正
func get_environment_efficiency_modifier():
	var modifier = 1.0
	
	# 温度影响
	if environment_data.temperature < temperature_effect.min_safe or environment_data.temperature > temperature_effect.max_safe:
		modifier *= 0.8
	
	# 氧气影响
	if environment_data.oxygen_level < oxygen_effect.min_safe:
		modifier *= 0.9
	
	# 毒性影响
	if environment_data.toxicity > 0.5:
		modifier *= 0.7
	
	# 辐射影响
	if environment_data.radiation > 0.5:
		modifier *= 0.6
	
	return modifier 