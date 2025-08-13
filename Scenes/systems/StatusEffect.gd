extends RefCounted
class_name StatusEffect

## 状态效果基类
## 所有宝石技能效果都继承自这个类

var target: Node
var effect_type: String
var duration: float = 0.0
var max_duration: float = 0.0
var stacks: int = 1
var max_stacks: int = 10
var intensity: float = 1.0

# 效果数据
var data: Dictionary = {}

func initialize(target_node: Node, type: String, dur: float, initial_stacks: int = 1) -> void:
	target = target_node
	effect_type = type
	duration = dur
	max_duration = dur
	stacks = initial_stacks
	
	# 设置效果特定数据
	setup_effect_data()
	
	# 应用初始效果
	on_effect_applied()

func setup_effect_data() -> void:
	# 根据效果类型设置数据
	match effect_type:
		"burn":
			data = {"damage_per_second": 5.0, "element": "fire"}
			max_stacks = 20
		"frost":
			data = {"slow_per_stack": 0.02, "damage_bonus": 0.02}
			max_stacks = 15
		"freeze":
			data = {"freeze_damage_multiplier": 2.0, "shatter_on_damage": true}
			max_stacks = 1  # 冻结不能叠加
		"shock":
			data = {"damage_multiplier": 1.0, "chain_chance": 0.3}
			max_stacks = 10
		"corruption":
			data = {"damage_per_second": 3.0, "defense_reduction": 0.01}
			max_stacks = 25
		"armor_break":
			data = {"defense_reduction_percent": 0.05}
			max_stacks = 10
		"slow":
			data = {"speed_reduction": 0.1}
			max_stacks = 5
		"weight":
			data = {"speed_reduction_per_stack": 0.015, "defense_reduction_per_stack": 1.0}
			max_stacks = 15
		"petrify":
			data = {"damage_reduction": 0.5, "immobilized": true}
			max_stacks = 1
		"life_steal":
			data = {"steal_percentage": 0.1}
			max_stacks = 1
		"imbalance":
			data = {"miss_chance": 0.30}
			max_stacks = 1
		"knockback":
			data = {"knockback_force": 100.0}
			max_stacks = 1
		"silence":
			data = {"disable_skills": true}
			max_stacks = 1
		"blind":
			data = {"miss_chance": 0.50, "accuracy_reduction": 0.50}
			max_stacks = 1
		"purify":
			data = {"remove_buffs": true, "heal_amount": 0, "energy_return": 0}
			max_stacks = 1
		"judgment":
			data = {"damage_taken_multiplier": 1.20, "holy_damage_on_death": true, "duration": 5.0}
			max_stacks = 1
		"corrosion":
			data = {"damage_per_second": 4.0, "defense_reduction": 0.01, "life_steal_percent": 0.0}
			max_stacks = 25
		"fear":
			data = {"miss_chance": 0.50, "movement_away": true, "fear_duration": 2.0}
			max_stacks = 1
		"life_drain":
			data = {"drain_percent": 0.10, "healing_reduction": 0.0, "duration": 3.0}
			max_stacks = 10
		_:
			data = {}

func update(delta: float) -> bool:
	# 更新持续时间
	duration -= delta
	
	# 应用持续效果
	apply_continuous_effect(delta)
	
	# 检查是否应该移除
	if duration <= 0:
		on_effect_removed()
		return true
	
	return false

func apply_continuous_effect(delta: float) -> void:
	# 子类可以重写这个方法，或者使用通用逻辑
	match effect_type:
		"burn":
			apply_burn_damage(delta)
		"frost":
			apply_frost_effect()
		"freeze":
			apply_freeze_effect()
		"shock":
			apply_shock_effect()
		"corruption":
			apply_corruption_damage(delta)
		"armor_break":
			apply_armor_break()
		"slow":
			apply_slow_effect()
		"weight":
			apply_weight_effect()
		"petrify":
			apply_petrify_effect()
		"imbalance":
			apply_imbalance_effect()
		"knockback":
			apply_knockback_effect()
		"silence":
			apply_silence_effect()
		"blind":
			apply_blind_effect()
		"purify":
			apply_purify_effect()
		"judgment":
			apply_judgment_effect()
		"corrosion":
			apply_corrosion_effect(delta)
		"fear":
			apply_fear_effect()
		"life_drain":
			apply_life_drain_effect(delta)

func apply_burn_damage(delta: float) -> void:
	if not target or not target.has_method("take_damage"):
		return
	
	var damage_per_second = data.get("damage_per_second", 5.0)
	var total_damage = damage_per_second * stacks * delta * intensity
	
	# 应用火焰伤害
	target.take_damage(total_damage, "fire")

func apply_frost_effect() -> void:
	if not target:
		return
	
	var slow_per_stack = data.get("slow_per_stack", 0.02)
	var damage_bonus = data.get("damage_bonus", 0.02)
	var slow_amount = slow_per_stack * stacks
	
	# 应用减速效果
	if target.has_method("apply_speed_modifier"):
		target.apply_speed_modifier("frost", max(0.1, 1.0 - slow_amount))
	
	# 应用冰霜伤害加成标记
	if target.has_method("set_frost_stacks"):
		target.set_frost_stacks(stacks)

func apply_freeze_effect() -> void:
	if not target:
		return
	
	# 冻结是硬控效果，完全停止目标
	if target.has_method("set_frozen"):
		target.set_frozen(true, duration)
	
	# 应用冰冻伤害倍率
	if target.has_method("set_freeze_damage_multiplier"):
		var damage_multiplier = data.get("freeze_damage_multiplier", 2.0)
		target.set_freeze_damage_multiplier(damage_multiplier)

func apply_shock_effect() -> void:
	# 感电效果在受到攻击时触发额外伤害
	# 这里只需要确保目标知道自己处于感电状态
	if target and target.has_method("set_shocked"):
		target.set_shocked(true, stacks)

func apply_corruption_damage(delta: float) -> void:
	if not target or not target.has_method("take_damage"):
		return
	
	var damage_per_second = data.get("damage_per_second", 3.0)
	var defense_reduction = data.get("defense_reduction", 0.01)
	
	# 应用腐蚀伤害
	var total_damage = damage_per_second * stacks * delta * intensity
	target.take_damage(total_damage, "shadow")
	
	# 应用防御力降低
	if target.has_method("apply_defense_modifier"):
		var total_reduction = defense_reduction * stacks
		target.apply_defense_modifier("corruption", 1.0 - total_reduction)

func apply_armor_break() -> void:
	if not target or not target.has_method("apply_defense_modifier"):
		return
	
	var reduction_percent = data.get("defense_reduction_percent", 0.05)
	var total_reduction = reduction_percent * stacks
	target.apply_defense_modifier("armor_break", 1.0 - total_reduction)

func apply_slow_effect() -> void:
	if not target or not target.has_method("apply_speed_modifier"):
		return
	
	var speed_reduction = data.get("speed_reduction", 0.1)
	var total_reduction = speed_reduction * min(stacks, max_stacks)
	target.apply_speed_modifier("slow", max(0.1, 1.0 - total_reduction))

func apply_weight_effect() -> void:
	if not target:
		return
	
	var speed_reduction_per_stack = data.get("speed_reduction_per_stack", 0.015)
	var defense_reduction_per_stack = data.get("defense_reduction_per_stack", 1.0)
	
	var total_speed_reduction = speed_reduction_per_stack * stacks
	var total_defense_reduction = defense_reduction_per_stack * stacks
	
	# 应用减速效果
	if target.has_method("apply_speed_modifier"):
		target.apply_speed_modifier("weight", max(0.1, 1.0 - total_speed_reduction))
	
	# 应用防御力降低
	if target.has_method("apply_defense_modifier"):
		target.apply_defense_modifier("weight", max(0.1, 1.0 - total_defense_reduction / 100.0))

func apply_petrify_effect() -> void:
	if not target:
		return
	
	# 石化是硬控效果，完全停止目标并提升防御
	if target.has_method("set_petrified"):
		target.set_petrified(true, duration)
	
	# 应用伤害减免（石化状态下防御力提升）
	if target.has_method("apply_defense_modifier"):
		var damage_reduction = data.get("damage_reduction", 0.5)
		target.apply_defense_modifier("petrify", 1.0 + damage_reduction)

func apply_imbalance_effect() -> void:
	if not target:
		return
	
	# 失衡效果使目标攻击有30%几率落空
	if target.has_method("set_imbalanced"):
		var miss_chance = data.get("miss_chance", 0.30)
		target.set_imbalanced(true, miss_chance, duration)

func apply_knockback_effect() -> void:
	if not target:
		return
	
	# 击退效果立即生效，推动目标
	if target.has_method("apply_knockback"):
		var force = data.get("knockback_force", 100.0)
		target.apply_knockback(force * intensity)

func apply_silence_effect() -> void:
	if not target:
		return
	
	# 沉默效果禁用目标技能
	if target.has_method("set_silenced"):
		target.set_silenced(true, duration)

func apply_blind_effect() -> void:
	if not target:
		return
	
	# 致盲效果使目标攻击有50%几率落空
	if target.has_method("set_blinded"):
		var miss_chance = data.get("miss_chance", 0.50)
		target.set_blinded(true, miss_chance, duration)

func apply_purify_effect() -> void:
	if not target:
		return
	
	# 净化效果移除敌人的增益效果
	if target.has_method("purify_buffs"):
		target.purify_buffs()
	
	# 如果设置了治疗量，则治疗目标
	var heal_amount = data.get("heal_amount", 0)
	if heal_amount > 0 and target.has_method("heal"):
		target.heal(heal_amount)
	
	# 如果设置了能量返还，则返还能量
	var energy_return = data.get("energy_return", 0)
	if energy_return > 0 and target.has_method("restore_energy"):
		target.restore_energy(energy_return)

func apply_judgment_effect() -> void:
	if not target:
		return
	
	# 审判效果使目标受到的伤害增加20%
	if target.has_method("set_judgment"):
		var damage_multiplier = data.get("damage_taken_multiplier", 1.20)
		target.set_judgment(true, damage_multiplier, duration)
	
	# 设置死亡时造成神圣伤害
	if target.has_method("set_holy_damage_on_death"):
		target.set_holy_damage_on_death(true)

func apply_corrosion_effect(delta: float) -> void:
	if not target or not target.has_method("take_damage"):
		return
	
	var damage_per_second = data.get("damage_per_second", 4.0)
	var defense_reduction = data.get("defense_reduction", 0.01)
	var life_steal_percent = data.get("life_steal_percent", 0.0)
	
	# 应用腐蚀伤害
	var total_damage = damage_per_second * stacks * delta * intensity
	target.take_damage(total_damage, "shadow")
	
	# 应用防御力降低
	if target.has_method("apply_defense_modifier"):
		var total_reduction = defense_reduction * stacks
		target.apply_defense_modifier("corrosion", 1.0 - total_reduction)
	
	# 应用生命虹吸效果
	if life_steal_percent > 0 and target.has_method("apply_life_drain"):
		target.apply_life_drain(life_steal_percent * stacks)

func apply_fear_effect() -> void:
	if not target:
		return
	
	var miss_chance = data.get("miss_chance", 0.50)
	var fear_duration = data.get("fear_duration", 2.0)
	
	# 恐惧效果使目标攻击可能落空并移动不受控制
	if target.has_method("set_feared"):
		target.set_feared(true, miss_chance, fear_duration)

func apply_life_drain_effect(delta: float) -> void:
	if not target or not target.has_method("take_damage"):
		return
	
	var drain_percent = data.get("drain_percent", 0.10)
	var healing_reduction = data.get("healing_reduction", 0.0)
	
	# 应用生命虹吸伤害
	if target.has_method("get_max_health"):
		var max_health = target.get_max_health()
		var drain_damage = max_health * drain_percent * stacks * delta * intensity
		target.take_damage(drain_damage, "shadow")
	
	# 应用治疗效果降低
	if healing_reduction > 0 and target.has_method("apply_healing_reduction"):
		target.apply_healing_reduction(healing_reduction * stacks)

## 效果管理方法

func add_stack(amount: int = 1) -> void:
	var old_stacks = stacks
	stacks = min(stacks + amount, max_stacks)
	
	if stacks != old_stacks:
		on_stacks_changed(old_stacks, stacks)

func remove_stack(amount: int = 1) -> void:
	var old_stacks = stacks
	stacks = max(1, stacks - amount)
	
	if stacks != old_stacks:
		on_stacks_changed(old_stacks, stacks)

func refresh_duration(new_duration: float) -> void:
	duration = max(duration, new_duration)
	max_duration = max(max_duration, new_duration)

func get_remaining_time() -> float:
	return duration

func get_progress() -> float:
	if max_duration <= 0:
		return 0.0
	return 1.0 - (duration / max_duration)

func is_expired() -> bool:
	return duration <= 0

## 事件回调

func on_effect_applied() -> void:
	# 效果首次应用时调用
	apply_initial_effect()

func on_effect_removed() -> void:
	# 效果移除时调用，清理状态
	cleanup_effect()

func on_stacks_changed(old_stacks: int, new_stacks: int) -> void:
	# 层数变化时重新应用效果
	if target:
		match effect_type:
			"frost", "slow", "armor_break", "weight":
				# 这些效果需要立即更新数值
				apply_continuous_effect(0.0)

func apply_initial_effect() -> void:
	# 应用即时效果
	match effect_type:
		"knockback":
			apply_knockback()
		"stun", "freeze", "petrify":
			apply_control_effect()
		"silence":
			apply_silence()

func apply_knockback() -> void:
	if target and target.has_method("apply_knockback"):
		var force = data.get("knockback_force", 100.0)
		target.apply_knockback(force * intensity)

func apply_control_effect() -> void:
	if target and target.has_method("set_controlled"):
		target.set_controlled(true, effect_type)

func apply_silence() -> void:
	if target and target.has_method("set_silenced"):
		target.set_silenced(true)

func cleanup_effect() -> void:
	# 清理效果状态
	if not target:
		return
	
	match effect_type:
		"frost", "slow", "weight":
			if target.has_method("remove_speed_modifier"):
				target.remove_speed_modifier(effect_type)
			if effect_type == "frost" and target.has_method("set_frost_stacks"):
				target.set_frost_stacks(0)
		"armor_break", "corruption", "weight", "petrify":
			if target.has_method("remove_defense_modifier"):
				target.remove_defense_modifier(effect_type)
		"stun", "petrify":
			if target.has_method("set_controlled"):
				target.set_controlled(false, effect_type)
		"petrify":
			if target.has_method("set_petrified"):
				target.set_petrified(false, 0)
		"freeze":
			if target.has_method("set_frozen"):
				target.set_frozen(false, 0)
			if target.has_method("set_freeze_damage_multiplier"):
				target.set_freeze_damage_multiplier(1.0)
		"silence":
			if target.has_method("set_silenced"):
				target.set_silenced(false, 0.0)
		"shock":
			if target.has_method("set_shocked"):
				target.set_shocked(false, 0)
		"imbalance":
			if target.has_method("set_imbalanced"):
				target.set_imbalanced(false, 0.0, 0.0)
		"knockback":
			# 击退效果是瞬时的，无需清理
			pass
		"blind":
			if target.has_method("set_blinded"):
				target.set_blinded(false, 0.0, 0.0)
		"judgment":
			if target.has_method("set_judgment"):
				target.set_judgment(false, 1.0, 0.0)
			if target.has_method("set_holy_damage_on_death"):
				target.set_holy_damage_on_death(false)
		"corrosion":
			if target.has_method("remove_defense_modifier"):
				target.remove_defense_modifier("corrosion")
			if target.has_method("remove_life_drain"):
				target.remove_life_drain()
		"fear":
			if target.has_method("set_feared"):
				target.set_feared(false, 0.0, 0.0)
		"life_drain":
			if target.has_method("remove_healing_reduction"):
				target.remove_healing_reduction()

func reset() -> void:
	# 重置效果状态，用于对象池回收
	target = null
	effect_type = ""
	duration = 0.0
	max_duration = 0.0
	stacks = 1
	intensity = 1.0
	data.clear()

## 调试和显示

func get_display_name() -> String:
	match effect_type:
		"burn": return "灼烧"
		"frost": return "冰霜"
		"freeze": return "冻结"
		"shock": return "感电"
		"corruption": return "腐蚀"
		"armor_break": return "破甲"
		"slow": return "减速"
		"weight": return "重压"
		"stun": return "眩晕"
		"silence": return "沉默"
		"petrify": return "石化"
		"paralysis": return "麻痹"
		"knockback": return "击退"
		"life_steal": return "生命偷取"
		"imbalance": return "失衡"
		"blind": return "致盲"
		"purify": return "净化"
		"judgment": return "审判"
		"corrosion": return "腐蚀"
		"fear": return "恐惧"
		"life_drain": return "生命虹吸"
		_: return effect_type.capitalize()

func get_description() -> String:
	var desc = get_display_name()
	if stacks > 1:
		desc += " x" + str(stacks)
	desc += " (" + "%.1f" % duration + "s)"
	return desc

func get_icon_path() -> String:
	return "res://Assets/effects/" + effect_type + ".png"