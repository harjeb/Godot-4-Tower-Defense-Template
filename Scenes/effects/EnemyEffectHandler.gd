extends Node2D
class_name EnemyEffectHandler

# 效果状态
var burn_stacks: int = 0
var burn_damage_per_second: float = 0.0
var is_carbonized: bool = false
var is_imprisoned: bool = false
var is_vulnerable: bool = false
var vulnerability_multiplier: float = 1.0

# 效果计时器
var effect_timers: Dictionary = {}

func _ready():
	set_process(true)

func _process(delta):
	# 处理持续伤害效果
	if burn_stacks > 0 and burn_damage_per_second > 0:
		# 每秒造成灼烧伤害
		if fmod(Time.get_ticks_msec() / 1000.0, 1.0) < delta:
			if has_method("take_damage"):
				take_damage(burn_damage_per_second * burn_stacks)

# 应用灼烧效果
func apply_burn(stacks: int, damage_per_second: float):
	burn_stacks += stacks
	burn_damage_per_second = damage_per_second
	
	# 刷新灼烧持续时间
	_setup_effect_timer("burn", 3.0)

# 移除灼烧效果
func remove_burn():
	burn_stacks = 0
	burn_damage_per_second = 0.0
	_clear_effect_timer("burn")

# 应用炭化效果
func apply_carbonization():
	is_carbonized = true
	# 炭化时无法移动和攻击
	if has_method("set_movement_disabled"):
		set_movement_disabled(true)
	if has_method("set_attack_disabled"):
		set_attack_disabled(true)

# 移除炭化效果
func remove_carbonization():
	is_carbonized = false
	if has_method("set_movement_disabled"):
		set_movement_disabled(false)
	if has_method("set_attack_disabled"):
		set_attack_disabled(false)

# 应用禁锢效果
func apply_imprison():
	is_imprisoned = true
	# 禁锢时无法移动
	if has_method("set_movement_disabled"):
		set_movement_disabled(true)

# 移除禁锢效果
func remove_imprison():
	is_imprisoned = false
	if has_method("set_movement_disabled"):
		set_movement_disabled(false)

# 应用脆弱效果
func apply_vulnerability(damage_increase: float):
	is_vulnerable = true
	vulnerability_multiplier = 1.0 + damage_increase

# 移除脆弱效果
func remove_vulnerability():
	is_vulnerable = false
	vulnerability_multiplier = 1.0

# 获取最终伤害倍率（考虑脆弱效果）
func get_damage_multiplier() -> float:
	return vulnerability_multiplier

# 设置效果计时器
func _setup_effect_timer(effect_name: String, duration: float):
	_clear_effect_timer(effect_name)
	
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_effect_timeout.bind(effect_name))
	
	add_child(timer)
	timer.start()
	effect_timers[effect_name] = timer

# 清除效果计时器
func _clear_effect_timer(effect_name: String):
	if effect_timers.has(effect_name):
		var timer = effect_timers[effect_name]
		if is_instance_valid(timer):
			timer.queue_free()
		effect_timers.erase(effect_name)

# 效果超时回调
func _on_effect_timeout(effect_name: String):
	match effect_name:
		"burn":
			remove_burn()
		"carbonization":
			remove_carbonization()
		"imprison":
			remove_imprison()
		"vulnerability":
			remove_vulnerability()

# 获取当前效果状态信息
func get_effect_status() -> Dictionary:
	return {
		"burn_stacks": burn_stacks,
		"burn_damage_per_second": burn_damage_per_second,
		"is_carbonized": is_carbonized,
		"is_imprisoned": is_imprisoned,
		"is_vulnerable": is_vulnerable,
		"vulnerability_multiplier": vulnerability_multiplier
	}

# 清除所有效果
func clear_all_effects():
	remove_burn()
	remove_carbonization()
	remove_imprison()
	remove_vulnerability()
	
	# 清除所有计时器
	for timer in effect_timers.values():
		if is_instance_valid(timer):
			timer.queue_free()
	effect_timers.clear()