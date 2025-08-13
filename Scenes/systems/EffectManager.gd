extends Node
class_name EffectManager

signal effect_applied(target: Node, effect_name: String, effect_data: Dictionary)
signal effect_removed(target: Node, effect_name: String)

var active_effects: Dictionary = {}  # target_id -> [effects]
var effect_timers: Dictionary = {}   # target_id -> Timer

func _ready():
	set_process(true)

func apply_effect(target: Node, effect_name: String, effect_data: Dictionary, source: Node = null) -> bool:
	if not is_instance_valid(target):
		push_warning("Cannot apply effect '" + effect_name + "': target is invalid")
		return false
	
	if effect_name.is_empty():
		push_error("Cannot apply effect: effect_name is empty")
		return false
	
	if effect_data.is_empty():
		push_error("Cannot apply effect '" + effect_name + "': effect_data is empty")
		return false
	
	var target_id = target.get_instance_id()
	
	if not active_effects.has(target_id):
		active_effects[target_id] = []
	
	var stacks = 1
	if effect_data.has("stacks"):
		stacks = effect_data.get("stacks")
	
	var effect = {
		"name": effect_name,
		"data": effect_data,
		"start_time": Time.get_ticks_msec(),
		"source": source,
		"stacks": stacks
	}
	
	# 处理可叠加效果
	var debuff_type = ""
	if effect_data.has("debuff_type"):
		debuff_type = effect_data.get("debuff_type")
	if debuff_type == "burn":
		_handle_burn_stacking(target, effect)
	else:
		active_effects[target_id].append(effect)
		_apply_single_effect(target, effect)
	
	# 设置持续时间计时器
	if effect_data.has("duration"):
		_setup_effect_timer(target, effect)
	
	effect_applied.emit(target, effect_name, effect_data)
	return true

func _handle_burn_stacking(target: Node, new_effect: Dictionary) -> void:
	if not is_instance_valid(target):
		return
	
	var target_id = target.get_instance_id()
	
	if not active_effects.has(target_id):
		active_effects[target_id] = []
	
	# 查找现存的灼烧效果
	var existing_burn = null
	for effect in active_effects[target_id]:
		var effect_debuff_type = ""
		if effect.data.has("debuff_type"):
			effect_debuff_type = effect.data.get("debuff_type")
		if effect_debuff_type == "burn":
			existing_burn = effect
			break
	
	if existing_burn:
		# 叠加灼烧层数
		existing_burn.stacks += new_effect.stacks
		existing_burn.start_time = Time.get_ticks_msec()  # 刷新持续时间
		# 重新应用效果以更新层数
		_apply_single_effect(target, existing_burn)
	else:
		# 添加新的灼烧效果
		active_effects[target_id].append(new_effect)
		_apply_single_effect(target, new_effect)

func _apply_single_effect(target: Node, effect: Dictionary) -> void:
	if not is_instance_valid(target) or effect.is_empty():
		return
	
	var effect_data = effect.get("data", {})
	if effect_data.is_empty():
		push_warning("Effect data is empty for target: " + str(target.name))
		return
	
	var effect_type = effect_data.get("type", "")
	match effect_type:
		"debuff":
			_apply_debuff(target, effect)
		"stat_modifier":
			_apply_stat_modifier(target, effect)
		"attack_modifier":
			_apply_attack_modifier(target, effect)
		"damage_modifier":
			_apply_damage_modifier(target, effect)

func _apply_debuff(target: Node, effect: Dictionary):
	var debuff_type = effect.data.get("debuff_type") if effect.data.has("debuff_type") else ""
	
	match debuff_type:
		"burn":
			if target.has_method("apply_burn"):
				target.apply_burn(effect.stacks, effect.data.damage_per_second)
		"炭化":
			if target.has_method("apply_carbonization"):
				target.apply_carbonization()
		"禁锢":
			if target.has_method("apply_imprison"):
				target.apply_imprison()
		"脆弱":
			if target.has_method("apply_vulnerability"):
				target.apply_vulnerability(effect.data.get("damage_increase") if effect.data.has("damage_increase") else 0.25)

func _apply_stat_modifier(target: Node, effect: Dictionary):
	var stat = effect.data.get("stat")
	var operation = effect.data.get("operation")
	var value = effect.data.get("value")
	
	if target.has_method("apply_stat_modifier"):
		target.apply_stat_modifier(stat, operation, value)

func _apply_attack_modifier(target: Node, effect: Dictionary):
	var property = effect.data.get("property")
	var value = effect.data.get("value")
	
	if target.has_method("apply_attack_modifier"):
		target.apply_attack_modifier(property, value)

func _apply_damage_modifier(target: Node, effect: Dictionary):
	var target_element = effect.data.get("target_element")
	var multiplier = effect.data.get("multiplier")
	
	if target.has_method("apply_damage_modifier"):
		target.apply_damage_modifier(target_element, multiplier)

func _setup_effect_timer(target: Node, effect: Dictionary):
	var target_id = target.get_instance_id()
	var duration = effect.data.get("duration") if effect.data.has("duration") else 0.0
	
	if duration <= 0:
		return
	
	if not effect_timers.has(target_id):
		effect_timers[target_id] = {}
	
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_effect_timeout.bind(target, effect))
	
	add_child(timer)
	timer.start()
	
	effect_timers[target_id][effect.name] = timer

func _on_effect_timeout(target: Node, effect: Dictionary):
	remove_effect(target, effect.name)

func remove_effect(target: Node, effect_name: String):
	if not target or not is_instance_valid(target):
		return
	
	var target_id = target.get_instance_id()
	
	if not active_effects.has(target_id):
		return
	
	var effects = active_effects[target_id]
	for i in range(effects.size() - 1, -1, -1):
		var effect = effects[i]
		if effect.name == effect_name:
			# 移除效果
			_remove_single_effect(target, effect)
			effects.remove_at(i)
			effect_removed.emit(target, effect_name)
			break
	
	# 清理空的效果列表
	if effects.is_empty():
		active_effects.erase(target_id)
	
	# 清理计时器
	if effect_timers.has(target_id):
		var timers = effect_timers[target_id]
		if timers.has(effect_name):
			var timer = timers[effect_name]
			if is_instance_valid(timer):
				timer.queue_free()
			timers.erase(effect_name)
		
		if timers.is_empty():
			effect_timers.erase(target_id)

func _remove_single_effect(target: Node, effect: Dictionary):
	var effect_data = effect.data
	
	match effect_data.type:
		"debuff":
			_remove_debuff(target, effect)
		"stat_modifier":
			_remove_stat_modifier(target, effect)
		"attack_modifier":
			_remove_attack_modifier(target, effect)
		"damage_modifier":
			_remove_damage_modifier(target, effect)

func _remove_debuff(target: Node, effect: Dictionary):
	var debuff_type = effect.data.get("debuff_type") if effect.data.has("debuff_type") else ""
	
	match debuff_type:
		"burn":
			if target.has_method("remove_burn"):
				target.remove_burn()
		"炭化":
			if target.has_method("remove_carbonization"):
				target.remove_carbonization()
		"禁锢":
			if target.has_method("remove_imprison"):
				target.remove_imprison()
		"脆弱":
			if target.has_method("remove_vulnerability"):
				target.remove_vulnerability()

func _remove_stat_modifier(target: Node, effect: Dictionary):
	var stat = effect.data.get("stat")
	var operation = effect.data.get("operation")
	var value = effect.data.get("value")
	
	if target.has_method("remove_stat_modifier"):
		target.remove_stat_modifier(stat, operation, value)

func _remove_attack_modifier(target: Node, effect: Dictionary):
	var property = effect.data.get("property")
	var value = effect.data.get("value")
	
	if target.has_method("remove_attack_modifier"):
		target.remove_attack_modifier(property, value)

func _remove_damage_modifier(target: Node, effect: Dictionary):
	var target_element = effect.data.get("target_element")
	var multiplier = effect.data.get("multiplier")
	
	if target.has_method("remove_damage_modifier"):
		target.remove_damage_modifier(target_element, multiplier)

func _process(delta: float):
	update_effects(delta)

func update_effects(delta: float):
	var current_time = Time.get_ticks_msec()
	var to_remove = []
	
	for target_id in active_effects:
		var effects = active_effects[target_id]
		var target = instance_from_id(target_id)
		
		if not target or not is_instance_valid(target):
			to_remove.append(target_id)
			continue
			
		for i in range(effects.size() - 1, -1, -1):
			var effect = effects[i]
			var elapsed = (current_time - effect.start_time) / 1000.0
			
			# 处理持续伤害效果
			if effect.data.has("damage_per_second"):
				if fmod(elapsed, 1.0) < delta:  # 每秒造成伤害
					if target.has_method("take_damage"):
						target.take_damage(effect.data.damage_per_second * effect.stacks)
	
	# 清理无效目标
	for target_id in to_remove:
		active_effects.erase(target_id)
		if effect_timers.has(target_id):
			var timers = effect_timers[target_id]
			for timer in timers.values():
				if is_instance_valid(timer):
					timer.queue_free()
			effect_timers.erase(target_id)

func get_target_effects(target: Node) -> Array:
	if not target or not is_instance_valid(target):
		return []
	
	var target_id = target.get_instance_id()
	return active_effects.get(target_id) if active_effects.has(target_id) else []

func has_effect(target: Node, effect_name: String) -> bool:
	var effects = get_target_effects(target)
	for effect in effects:
		if effect.name == effect_name:
			return true
	return false

func get_effect_stacks(target: Node, effect_name: String) -> int:
	var effects = get_target_effects(target)
	for effect in effects:
		if effect.name == effect_name:
			return effect.stacks
	return 0

func clear_all_effects():
	# 清理所有效果和计时器
	for target_id in active_effects:
		if effect_timers.has(target_id):
			var timers = effect_timers[target_id]
			for timer in timers.values():
				if is_instance_valid(timer):
					timer.queue_free()
	
	active_effects.clear()
	effect_timers.clear()