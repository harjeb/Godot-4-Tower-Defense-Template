extends Node
class_name GemEffectSystem

## 优化的宝石效果系统
## 使用分层更新频率和对象池来提升性能

signal effect_applied(target: Node, effect_type: String)
signal effect_removed(target: Node, effect_type: String)

# 效果分组管理 - 不同更新频率
var effect_groups: Dictionary = {
	"high_freq": [],    # 每帧更新 - 控制效果
	"mid_freq": [],     # 每10帧更新 - 持续效果  
	"low_freq": []      # 每30帧更新 - 光环效果
}

var frame_counter: int = 0
var effect_pool: EffectPool
var active_effects_by_target: Dictionary = {}

# 效果类型到更新频率的映射
const EFFECT_UPDATE_FREQUENCY = {
	# 高频率 - 影响游戏手感的效果
	"freeze": "high_freq",
	"stun": "high_freq", 
	"knockback": "high_freq",
	"silence": "high_freq",
	"petrify": "high_freq",
	"paralysis": "high_freq",
	
	# 中频率 - 持续伤害和状态
	"burn": "mid_freq",
	"poison": "mid_freq",
	"frost": "mid_freq",
	"shock": "mid_freq",
	"corruption": "mid_freq",
	"slow": "mid_freq",
	"weight": "mid_freq",
	"armor_break": "mid_freq",
	"life_steal": "mid_freq",
	
	# 低频率 - 光环和被动效果
	"aura_damage": "low_freq",
	"aura_speed": "low_freq",
	"passive_regen": "low_freq",
	"environmental": "low_freq",
	
	# 光元素效果
	"blind": "high_freq",
	"purify": "mid_freq", 
	"judgment": "mid_freq",
	
	# 暗元素效果
	"corrosion": "mid_freq",
	"fear": "high_freq",
	"life_drain": "mid_freq"
}

func _ready() -> void:
	effect_pool = EffectPool.new()
	add_child(effect_pool)
	
	# 连接到全局系统
	if not Globals.has_signal("game_paused"):
		Globals.connect("game_paused", _on_game_paused)

func _process(delta: float) -> void:
	if Globals.get("game_paused", false):
		return
	
	frame_counter += 1
	
	# 高频效果 - 每帧更新
	process_effect_group("high_freq", delta)
	
	# 中频效果 - 每10帧更新
	if frame_counter % 10 == 0:
		process_effect_group("mid_freq", delta * 10)
	
	# 低频效果 - 每30帧更新  
	if frame_counter % 30 == 0:
		process_effect_group("low_freq", delta * 30)

func process_effect_group(group_name: String, delta_time: float) -> void:
	var effects = effect_groups[group_name]
	
	# 从后往前遍历，安全移除过期效果
	for i in range(effects.size() - 1, -1, -1):
		var effect = effects[i]
		
		# 检查目标是否仍然有效
		if not is_instance_valid(effect.target):
			remove_effect_at_index(group_name, i)
			continue
		
		# 更新效果
		var should_remove = effect.update(delta_time)
		
		if should_remove:
			remove_effect_at_index(group_name, i)

func remove_effect_at_index(group_name: String, index: int) -> void:
	var effect = effect_groups[group_name][index]
	
	# 清理目标上的效果记录
	if active_effects_by_target.has(effect.target):
		var target_effects = active_effects_by_target[effect.target]
		target_effects.erase(effect)
		
		if target_effects.is_empty():
			active_effects_by_target.erase(effect.target)
	
	# 发射移除信号
	effect_removed.emit(effect.target, effect.effect_type)
	
	# 移除并回收到对象池
	effect_groups[group_name].remove_at(index)
	effect_pool.return_effect(effect)

## 公共API

# 应用效果到目标
func apply_effect(target: Node, effect_type: String, duration: float, stacks: int = 1) -> void:
	if not is_instance_valid(target):
		push_warning("Cannot apply effect to invalid target")
		return
	
	# 检查是否已有相同类型的效果
	var existing_effect = find_effect_on_target(target, effect_type)
	
	if existing_effect:
		# 刷新持续时间并叠加层数
		existing_effect.refresh_duration(duration)
		existing_effect.add_stack(stacks)
	else:
		# 创建新效果
		var effect = effect_pool.get_effect(effect_type)
		effect.initialize(target, effect_type, duration, stacks)
		
		# 添加到对应频率组
		var frequency = EFFECT_UPDATE_FREQUENCY.get(effect_type, "mid_freq")
		effect_groups[frequency].append(effect)
		
		# 记录到目标效果表
		if not active_effects_by_target.has(target):
			active_effects_by_target[target] = []
		active_effects_by_target[target].append(effect)
		
		effect_applied.emit(target, effect_type)

# 移除目标上的特定效果
func remove_effect(target: Node, effect_type: String) -> bool:
	var effect = find_effect_on_target(target, effect_type)
	if not effect:
		return false
	
	# 找到效果所在的组并移除
	for group_name in effect_groups.keys():
		var index = effect_groups[group_name].find(effect)
		if index != -1:
			remove_effect_at_index(group_name, index)
			return true
	
	return false

# 清除目标上的所有效果
func clear_all_effects(target: Node) -> void:
	if not active_effects_by_target.has(target):
		return
	
	var target_effects = active_effects_by_target[target].duplicate()
	
	for effect in target_effects:
		remove_effect(target, effect.effect_type)

# 获取目标上的效果列表
func get_effects_on_target(target: Node) -> Array:
	return active_effects_by_target.get(target, [])

# 检查目标是否有特定效果
func has_effect(target: Node, effect_type: String) -> bool:
	return find_effect_on_target(target, effect_type) != null

# 获取特定效果的层数
func get_effect_stacks(target: Node, effect_type: String) -> int:
	var effect = find_effect_on_target(target, effect_type)
	return effect.stacks if effect else 0

## 私有方法

func find_effect_on_target(target: Node, effect_type: String) -> StatusEffect:
	if not active_effects_by_target.has(target):
		return null
	
	for effect in active_effects_by_target[target]:
		if effect.effect_type == effect_type:
			return effect
	
	return null

func _on_game_paused(paused: bool) -> void:
	# 游戏暂停时停止处理效果
	set_process(not paused)

# 性能监控
func get_performance_stats() -> Dictionary:
	var total_effects = 0
	for group in effect_groups.values():
		total_effects += group.size()
	
	return {
		"total_effects": total_effects,
		"high_freq_effects": effect_groups["high_freq"].size(),
		"mid_freq_effects": effect_groups["mid_freq"].size(), 
		"low_freq_effects": effect_groups["low_freq"].size(),
		"targets_with_effects": active_effects_by_target.size(),
		"pooled_effects": effect_pool.get_pool_size()
	}

# 调试信息
func print_debug_info() -> void:
	var stats = get_performance_stats()
	print("GemEffectSystem Debug:")
	print("  Total Effects: ", stats.total_effects)
	print("  High Freq: ", stats.high_freq_effects)
	print("  Mid Freq: ", stats.mid_freq_effects)
	print("  Low Freq: ", stats.low_freq_effects)
	print("  Affected Targets: ", stats.targets_with_effects)

# 冰元素特效方法

# 应用冰霜区域效果
func apply_frost_area(center: Vector2, radius: float, stacks: int = 1, duration: float = 4.0) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	# 获取范围内的所有敌人
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_effect(enemy, "frost", duration, stacks)

# 应用冻结效果（带几率）
func apply_chance_freeze(target: Node, chance: float, duration: float) -> void:
	if randf() < chance:
		apply_effect(target, "freeze", duration, 1)

# 应用冰霜地面效果
func apply_frost_ground(center: Vector2, radius: float, duration: float) -> void:
	# 创建冰霜地面区域效果
	# 这里需要根据游戏的具体实现来处理
	pass

# 检查目标是否被冻结
func is_target_frozen(target: Node) -> bool:
	return has_effect(target, "freeze")

# 获取目标的冰霜层数
func get_frost_stacks(target: Node) -> int:
	return get_effect_stacks(target, "frost")

# 对冻结目标造成额外伤害
func apply_frozen_damage_bonus(base_damage: float, target: Node) -> float:
	if is_target_frozen(target):
		return base_damage * 3.0  # 3倍伤害
	return base_damage

# 辅助方法：获取区域内的敌人
func get_enemies_in_area(center: Vector2, radius: float) -> Array:
	var enemies = []
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return enemies
	
	# 查找所有敌人节点
	var enemy_nodes = tree.current_scene.get_tree().get_nodes_in_group("enemy")
	for enemy in enemy_nodes:
		if is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(center)
			if distance <= radius:
				enemies.append(enemy)
	
	return enemies

# 应用冰霜弹射效果
func apply_frost_on_bounce(target: Node, stacks: int = 1, duration: float = 4.0) -> void:
	apply_effect(target, "frost", duration, stacks)

# 应用冰霜光环效果
func apply_frost_aura(center: Vector2, radius: float, slow_amount: float) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		# 应用减速效果
		if enemy.has_method("apply_speed_modifier"):
			enemy.apply_speed_modifier("frost_aura", 1.0 - slow_amount)

# 移除冰霜光环效果
func remove_frost_aura(center: Vector2, radius: float) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("remove_speed_modifier"):
			enemy.remove_speed_modifier("frost_aura")

# 土元素特效方法

# 应用重压区域效果
func apply_weight_area(center: Vector2, radius: float, stacks: int = 1, duration: float = 4.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_effect(enemy, "weight", duration, stacks)

# 应用重压效果到所有地面单位
func apply_weight_all_ground(stacks: int = 1, duration: float = 4.0) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var enemy_nodes = tree.current_scene.get_tree().get_nodes_in_group("enemy")
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.get("movement_type") == "ground":
			apply_effect(enemy, "weight", duration, stacks)

# 应用石化效果（带几率）
func apply_chance_petrify(target: Node, chance: float, duration: float) -> void:
	if randf() < chance:
		apply_effect(target, "petrify", duration, 1)

# 检查目标是否被石化
func is_target_petrified(target: Node) -> bool:
	return has_effect(target, "petrify")

# 应用破甲弹射效果
func apply_armor_break_on_bounce(target: Node, stacks: int = 1, duration: float = 5.0) -> void:
	apply_effect(target, "armor_break", duration, stacks)

# 应用连续防御力降低效果
func apply_continuous_defense_reduction(target: Node, max_reduction: float, duration: float = 10.0) -> void:
	# 这个效果需要特殊处理，在目标上持续降低防御力
	# 可以通过定时器或持续效果来实现
	apply_effect(target, "armor_break", duration, 1)  # 简化实现，实际需要更复杂的逻辑

# 应用最大生命值百分比伤害
func apply_max_hp_damage(target: Node, percentage: float) -> void:
	if target.has_method("take_damage") and target.has_method("get_max_health"):
		var max_hp = target.get_max_health()
		var damage = max_hp * percentage
		target.take_damage(damage, "earth")

# 应用余震效果
func apply_aftershock(center: Vector2, radius: float, damage_multiplier: float) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			# 简化实现，实际需要基于原伤害计算
			var base_damage = 20.0  # 基础余震伤害
			var total_damage = base_damage * damage_multiplier
			enemy.take_damage(total_damage, "earth")
			apply_effect(enemy, "armor_break", 3.0, 1)  # 余震附带破甲

# 应用护盾效果到友方塔
func apply_tower_shield(tower: Node, shield_amount: float) -> void:
	if tower.has_method("add_shield"):
		tower.add_shield(shield_amount)

# 检查目标是否有破甲效果
func has_armor_break(target: Node) -> bool:
	return has_effect(target, "armor_break")

# 获取目标的重压层数
func get_weight_stacks(target: Node) -> int:
	return get_effect_stacks(target, "weight")

# 应用永久重压领域（简化实现）
func apply_permanent_weight_field(center: Vector2, radius: float) -> void:
	# 实际实现需要创建持续的区域效果
	apply_weight_area(center, radius, 1, 999.0)  # 使用很长的持续时间模拟永久效果

# 风元素特效方法

# 应用失衡区域效果
func apply_imbalance_area(center: Vector2, radius: float, duration: float = 2.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_effect(enemy, "imbalance", duration, 1)

# 应用失衡效果到隐身单位
func apply_imbalance_stealth(center: Vector2, radius: float, duration: float = 2.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("get_is_stealthed") and enemy.get_is_stealthed():
			apply_effect(enemy, "imbalance", duration, 1)

# 应用沉默效果
func apply_silence(target: Node, duration: float = 3.0) -> void:
	apply_effect(target, "silence", duration, 1)

# 应用沉默效果到隐身单位
func apply_silence_stealth(center: Vector2, radius: float, duration: float = 3.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("get_is_stealthed") and enemy.get_is_stealthed():
			apply_effect(enemy, "silence", duration, 1)

# 应用击退效果
func apply_knockback(target: Node, force: float = 150.0) -> void:
	apply_effect(target, "knockback", 0.1, 1)  # 短持续时间，立即生效
	# 直接调用目标的击退方法
	if target and target.has_method("apply_knockback"):
		target.apply_knockback(force)

# 应用范围击退效果
func apply_knockback_all(center: Vector2, radius: float, force: float = 200.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_knockback(enemy, force)

# 应用飞行单位减益效果
func apply_flying_debuff(center: Vector2, radius: float, speed_reduction: float = 0.2, attack_speed_reduction: float = 0.2) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("is_flying") and enemy.is_flying():
			# 应用速度减益
			if enemy.has_method("apply_speed_modifier"):
				enemy.apply_speed_modifier("flying_debuff", 1.0 - speed_reduction)
			# 应用攻击速度减益
			if enemy.has_method("apply_attack_speed_modifier"):
				enemy.apply_attack_speed_modifier("flying_debuff", 1.0 - attack_speed_reduction)

# 应用放逐效果
func apply_exile(target: Node, duration: float = 8.0) -> void:
	if target and target.has_method("apply_exile"):
		target.apply_exile(duration)

# 应用龙卷风效果
func apply_tornado(center: Vector2, radius: float, duration: float = 4.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("apply_imprison"):
			enemy.apply_imprison(duration)
		# 同时施加失衡效果
		apply_effect(enemy, "imbalance", duration, 1)

# 应用飓风效果
func apply_hurricane(center: Vector2, radius: float, duration: float = 5.0, pull_force: float = 50.0, damage_per_second: float = 20.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("apply_hurricane"):
			enemy.apply_hurricane(center, duration, pull_force, damage_per_second)

# 应用攻击速度光环效果
func apply_attack_speed_aura(center: Vector2, radius: float, speed_bonus: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var towers = tree.current_scene.get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if is_instance_valid(tower) and tower != self:
			var distance = tower.global_position.distance_to(center)
			if distance <= radius:
				if tower.has_method("apply_attack_speed_bonus"):
					tower.apply_attack_speed_bonus(speed_bonus)

# 移除攻击速度光环效果
func remove_attack_speed_aura(center: Vector2, radius: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var towers = tree.current_scene.get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if is_instance_valid(tower):
			var distance = tower.global_position.distance_to(center)
			if distance <= radius:
				if tower.has_method("remove_attack_speed_bonus"):
					tower.remove_attack_speed_bonus()

# 检查目标是否被失衡
func is_target_imbalanced(target: Node) -> bool:
	return has_effect(target, "imbalance")

# 检查目标是否被沉默
func is_target_silenced(target: Node) -> bool:
	return has_effect(target, "silence")

# 应用弹射结束时的额外伤害
func apply_bonus_damage_on_end(target: Node, base_damage: float, damage_multiplier: float = 0.20) -> void:
	var bonus_damage = base_damage * damage_multiplier
	if target and target.has_method("take_damage"):
		target.take_damage(bonus_damage, "wind")

# 光元素特效方法

# 应用致盲效果
func apply_blind(target: Node, duration: float = 1.5, miss_chance: float = 0.50) -> void:
	apply_effect(target, "blind", duration, 1)
	# 设置致盲数据
	var effect = find_effect_on_target(target, "blind")
	if effect:
		effect.data["miss_chance"] = miss_chance

# 应用净化效果
func apply_purify(target: Node, duration: float = 0.0, heal_amount: float = 0.0, energy_return: float = 0.0) -> void:
	apply_effect(target, "purify", duration, 1)
	# 设置净化数据
	var effect = find_effect_on_target(target, "purify")
	if effect:
		effect.data["heal_amount"] = heal_amount
		effect.data["energy_return"] = energy_return

# 应用审判效果
func apply_judgment(target: Node, duration: float = 5.0, damage_multiplier: float = 1.20) -> void:
	apply_effect(target, "judgment", duration, 1)
	# 设置审判数据
	var effect = find_effect_on_target(target, "judgment")
	if effect:
		effect.data["damage_taken_multiplier"] = damage_multiplier

# 应用致盲区域效果
func apply_blind_area(center: Vector2, radius: float, duration: float = 1.5) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_blind(enemy, duration)

# 应用净化区域效果
func apply_purify_area(center: Vector2, radius: float, heal_amount: float = 0.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_purify(enemy, 0.0, heal_amount)

# 应用审判区域效果
func apply_judgment_area(center: Vector2, radius: float, duration: float = 5.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_judgment(enemy, duration)

# 应用致盲到隐身单位
func apply_blind_stealth(center: Vector2, radius: float, duration: float = 1.5) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("get_is_stealthed") and enemy.get_is_stealthed():
			apply_blind(enemy, duration)

# 应用治疗到友方塔
func heal_friendly_towers(center: Vector2, radius: float, heal_amount: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var towers = tree.current_scene.get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if is_instance_valid(tower) and tower != self:
			var distance = tower.global_position.distance_to(center)
			if distance <= radius:
				if tower.has_method("heal"):
					tower.heal(heal_amount)

# 应用能量返还到友方塔
func restore_energy_to_towers(center: Vector2, radius: float, energy_amount: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var towers = tree.current_scene.get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if is_instance_valid(tower) and tower != self:
			var distance = tower.global_position.distance_to(center)
			if distance <= radius:
				if tower.has_method("restore_energy"):
					tower.restore_energy(energy_amount)

# 检查目标是否被致盲
func is_target_blinded(target: Node) -> bool:
	return has_effect(target, "blind")

# 检查目标是否被审判
func is_target_judged(target: Node) -> bool:
	return has_effect(target, "judgment")

# 获取目标的致盲几率
func get_blind_miss_chance(target: Node) -> float:
	var effect = find_effect_on_target(target, "blind")
	if effect:
		return effect.data.get("miss_chance", 0.50)
	return 0.0

# 获取目标的审判伤害倍率
func get_judgment_damage_multiplier(target: Node) -> float:
	var effect = find_effect_on_target(target, "judgment")
	if effect:
		return effect.data.get("damage_taken_multiplier", 1.20)
	return 1.0

# 应用神圣伤害（对审判目标额外伤害）
func apply_holy_damage(target: Node, base_damage: float) -> float:
	if is_target_judged(target):
		var multiplier = get_judgment_damage_multiplier(target)
		return base_damage * multiplier
	return base_damage

# 审判扩散效果（死亡时对周围敌人造成神圣伤害）
func apply_judgment_spread(death_center: Vector2, radius: float, base_damage: float) -> void:
	var enemies = get_enemies_in_area(death_center, radius)
	for enemy in enemies:
		var holy_damage = apply_holy_damage(enemy, base_damage)
		if enemy.has_method("take_damage"):
			enemy.take_damage(holy_damage, "holy")

# 净化成功时的能量返还
func apply_purify_energy_return(tower: Node, energy_amount: float) -> void:
	if tower and tower.has_method("restore_energy"):
		tower.restore_energy(energy_amount)

# 应用优先攻击审判目标效果
func prioritize_judgment_targets(center: Vector2, radius: float) -> Array:
	var enemies = get_enemies_in_area(center, radius)
	var judged_targets = []
	var normal_targets = []
	
	for enemy in enemies:
		if is_target_judged(enemy):
			judged_targets.append(enemy)
		else:
			normal_targets.append(enemy)
	
	# 优先返回被审判的目标
	return judged_targets + normal_targets

# 暗元素特效方法

# 应用腐蚀效果
func apply_corrosion(target: Node, stacks: int = 1, duration: float = 4.0, life_steal_percent: float = 0.0) -> void:
	apply_effect(target, "corrosion", duration, stacks)
	# 设置生命虹吸百分比
	var effect = find_effect_on_target(target, "corrosion")
	if effect:
		effect.data["life_steal_percent"] = life_steal_percent

# 应用恐惧效果
func apply_fear(target: Node, duration: float = 2.0, miss_chance: float = 0.50) -> void:
	apply_effect(target, "fear", duration, 1)
	# 设置恐惧数据
	var effect = find_effect_on_target(target, "fear")
	if effect:
		effect.data["miss_chance"] = miss_chance

# 应用生命虹吸效果
func apply_life_drain(target: Node, drain_percent: float = 0.10, healing_reduction: float = 0.0, duration: float = 3.0) -> void:
	apply_effect(target, "life_drain", duration, 1)
	# 设置生命虹吸数据
	var effect = find_effect_on_target(target, "life_drain")
	if effect:
		effect.data["drain_percent"] = drain_percent
		effect.data["healing_reduction"] = healing_reduction

# 应用腐蚀区域效果
func apply_corrosion_area(center: Vector2, radius: float, stacks: int = 1, duration: float = 4.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_corrosion(enemy, stacks, duration)

# 应用恐惧区域效果
func apply_fear_area(center: Vector2, radius: float, duration: float = 2.0) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_fear(enemy, duration)

# 应用生命虹吸区域效果
func apply_life_drain_area(center: Vector2, radius: float, drain_percent: float = 0.10) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		apply_life_drain(enemy, drain_percent)

# 检查目标是否被腐蚀
func is_target_corroded(target: Node) -> bool:
	return has_effect(target, "corrosion")

# 检查目标是否被恐惧
func is_target_feared(target: Node) -> bool:
	return has_effect(target, "fear")

# 检查目标是否被生命虹吸
func is_target_life_drained(target: Node) -> bool:
	return has_effect(target, "life_drain")

# 获取目标的腐蚀层数
func get_corrosion_stacks(target: Node) -> int:
	return get_effect_stacks(target, "corrosion")

# 获取目标的恐惧命中率减少
func get_fear_miss_chance(target: Node) -> float:
	var effect = find_effect_on_target(target, "fear")
	if effect:
		return effect.data.get("miss_chance", 0.50)
	return 0.0

# 获取目标的生命虹吸百分比
func get_life_drain_percent(target: Node) -> float:
	var effect = find_effect_on_target(target, "life_drain")
	if effect:
		return effect.data.get("drain_percent", 0.10) * effect.stacks
	return 0.0

# 应用生命偷取效果（塔回复生命）
func apply_life_steal_to_tower(tower: Node, damage_dealt: float, steal_percentage: float) -> void:
	if tower and tower.has_method("heal"):
		var heal_amount = damage_dealt * steal_percentage
		tower.heal(heal_amount)

# 应用治疗效果降低
func apply_healing_reduction_to_target(target: Node, reduction_percent: float) -> void:
	if target and target.has_method("apply_healing_reduction"):
		target.apply_healing_reduction(reduction_percent)

# 移除治疗效果降低
func remove_healing_reduction_from_target(target: Node) -> void:
	if target and target.has_method("remove_healing_reduction"):
		target.remove_healing_reduction()

# 应用死亡传染效果（腐蚀扩散）
func apply_corrosion_contagion(death_center: Vector2, radius: float, corrosion_stacks: int) -> void:
	var enemies = get_enemies_in_area(death_center, radius)
	for enemy in enemies:
		apply_corrosion(enemy, corrosion_stacks, 4.0)

# 应用恐惧连锁效果
func apply_fear_chain(center: Vector2, radius: float, fear_duration: float = 1.5) -> void:
	var enemies = get_enemies_in_area(center, radius)
	for enemy in enemies:
		# 优先攻击未恐惧的目标
		if not is_target_feared(enemy):
			apply_fear(enemy, fear_duration)

# 应用永久属性偷取效果
func apply_permanent_stat_steal(tower: Node, stat_type: String, steal_amount: float) -> void:
	if tower and tower.has_method("apply_permanent_stat_boost"):
		tower.apply_permanent_stat_boost(stat_type, steal_amount)

# 应用无法治疗效果
func apply_no_healing_effect(target: Node, duration: float) -> void:
	if target and target.has_method("set_no_healing"):
		target.set_no_healing(true, duration)