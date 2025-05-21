extends Node

# 居民状态枚举
enum ColonistState {
	IDLE = 0,        # 空闲
	WORKING = 1,     # 工作
	EATING = 2,      # 进食
	SLEEPING = 3,    # 睡眠
	RECREATING = 4,  # 娱乐
	MEDICAL = 5      # 医疗
}

# 需求类型枚举
enum NeedType {
	OXYGEN = 0,     # 氧气需求
	WATER = 1,      # 水分需求
	FOOD = 2,       # 食物需求
	REST = 3,       # 休息需求
	RECREATION = 4, # 娱乐需求
	HEALTH = 5      # 健康需求
}

# 居民数据
var colonist_data = {
	"name": "",
	"state": ColonistState.IDLE,
	"needs": {
		NeedType.OXYGEN: {
			"current": 100.0,
			"max": 100.0,
			"decay_rate": 1.0,  # 每秒衰减量
			"critical_level": 20.0
		},
		NeedType.WATER: {
			"current": 100.0,
			"max": 100.0,
			"decay_rate": 0.5,
			"critical_level": 20.0
		},
		NeedType.FOOD: {
			"current": 100.0,
			"max": 100.0,
			"decay_rate": 0.3,
			"critical_level": 20.0
		},
		NeedType.REST: {
			"current": 100.0,
			"max": 100.0,
			"decay_rate": 0.2,
			"critical_level": 20.0
		},
		NeedType.RECREATION: {
			"current": 100.0,
			"max": 100.0,
			"decay_rate": 0.1,
			"critical_level": 20.0
		},
		NeedType.HEALTH: {
			"current": 100.0,
			"max": 100.0,
			"decay_rate": 0.0,  # 健康值不会自然衰减
			"critical_level": 20.0
		}
	},
	"skills": {
		"farming": 0.0,
		"engineering": 0.0,
		"research": 0.0,
		"medical": 0.0
	},
	"current_task": null,
	"current_room": null,
	"target_position": null,
	"move_speed": 100.0
}

# 信号
signal need_critical(need_type)
signal need_normal(need_type)
signal state_changed(new_state)
signal task_completed(task)

# 预加载资源系统
var resource_system = preload("res://scripts/resource_system.gd").new()

func _ready():
	# 初始化居民AI
	pass

func _process(delta):
	_update_needs(delta)
	_update_state()
	_update_movement(delta)

# 更新需求值
func _update_needs(delta):
	for need_type in colonist_data.needs:
		var need = colonist_data.needs[need_type]
		
		# 根据当前状态调整衰减率
		var actual_decay_rate = need.decay_rate
		match colonist_data.state:
			ColonistState.WORKING:
				if need_type == NeedType.REST:
					actual_decay_rate *= 2.0
				elif need_type == NeedType.RECREATION:
					actual_decay_rate *= 1.5
			ColonistState.SLEEPING:
				if need_type == NeedType.REST:
					actual_decay_rate = -5.0  # 恢复休息值
				elif need_type == NeedType.HEALTH:
					actual_decay_rate = -0.5  # 缓慢恢复健康值
		
		# 更新需求值
		need.current = clamp(need.current - actual_decay_rate * delta, 0.0, need.max)
		
		# 检查需求状态
		if need.current <= need.critical_level:
			emit_signal("need_critical", need_type)
		else:
			emit_signal("need_normal", need_type)

# 更新状态
func _update_state():
	var current_state = colonist_data.state
	var new_state = current_state
	
	# 检查是否需要改变状态
	for need_type in colonist_data.needs:
		var need = colonist_data.needs[need_type]
		if need.current <= need.critical_level:
			match need_type:
				NeedType.OXYGEN:
					new_state = ColonistState.IDLE  # 寻找氧气
				NeedType.WATER:
					new_state = ColonistState.IDLE  # 寻找水
				NeedType.FOOD:
					new_state = ColonistState.EATING
				NeedType.REST:
					new_state = ColonistState.SLEEPING
				NeedType.RECREATION:
					new_state = ColonistState.RECREATING
				NeedType.HEALTH:
					new_state = ColonistState.MEDICAL
	
	# 如果状态改变，发出信号
	if new_state != current_state:
		colonist_data.state = new_state
		emit_signal("state_changed", new_state)

# 更新移动
func _update_movement(delta):
	if colonist_data.target_position:
		var direction = (colonist_data.target_position - global_position).normalized()
		global_position += direction * colonist_data.move_speed * delta
		
		# 检查是否到达目标位置
		if global_position.distance_to(colonist_data.target_position) < 5.0:
			colonist_data.target_position = null
			_on_reached_destination()

# 设置目标位置
func set_target_position(position):
	colonist_data.target_position = position

# 到达目标位置时的处理
func _on_reached_destination():
	match colonist_data.state:
		ColonistState.EATING:
			_consume_food()
		ColonistState.SLEEPING:
			_rest()
		ColonistState.RECREATING:
			_recreate()
		ColonistState.MEDICAL:
			_receive_medical_care()
		ColonistState.WORKING:
			_work()

# 消耗食物
func _consume_food():
	if resource_system.has_enough_resource(resource_system.ResourceType.FOOD, 1.0):
		resource_system.consume_resource(resource_system.ResourceType.FOOD, 1.0)
		colonist_data.needs[NeedType.FOOD].current = colonist_data.needs[NeedType.FOOD].max

# 休息
func _rest():
	colonist_data.needs[NeedType.REST].current = colonist_data.needs[NeedType.REST].max

# 娱乐
func _recreate():
	colonist_data.needs[NeedType.RECREATION].current = colonist_data.needs[NeedType.RECREATION].max

# 接受医疗
func _receive_medical_care():
	colonist_data.needs[NeedType.HEALTH].current = colonist_data.needs[NeedType.HEALTH].max

# 工作
func _work():
	if colonist_data.current_task:
		# 执行工作任务
		pass

# 分配任务
func assign_task(task):
	colonist_data.current_task = task
	colonist_data.state = ColonistState.WORKING
	emit_signal("state_changed", ColonistState.WORKING)

# 获取需求值
func get_need(need_type):
	return colonist_data.needs[need_type].current

# 获取需求最大值
func get_need_max(need_type):
	return colonist_data.needs[need_type].max

# 获取当前状态
func get_state():
	return colonist_data.state

# 获取技能值
func get_skill(skill_name):
	return colonist_data.skills[skill_name]

# 提升技能
func improve_skill(skill_name, amount):
	colonist_data.skills[skill_name] = clamp(colonist_data.skills[skill_name] + amount, 0.0, 100.0) 