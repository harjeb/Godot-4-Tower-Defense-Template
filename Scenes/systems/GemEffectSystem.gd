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
var game_paused: bool = false

# 敌人查找缓存系统
var enemy_cache: Array = []
var enemy_cache_last_update: int = 0
var enemy_cache_update_interval: int = 5  # 每5帧更新一次缓存
var tower_cache: Array = []
var tower_cache_last_update: int = 0
var hero_cache: Array = []
var hero_cache_last_update: int = 0

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
	if game_paused:
		return
	
	frame_counter += 1
	
	# 内存监控
	_monitor_memory()
	
	# 高频效果 - 每帧更新
	process_effect_group("high_freq", delta)
	
	# 中频效果 - 每10帧更新
	if frame_counter % 10 == 0:
		process_effect_group("mid_freq", delta * 10)
	
	# 低频效果 - 每30帧更新  
	if frame_counter % 30 == 0:
		process_effect_group("low_freq", delta * 30)
	
	# 定期输出系统健康状态（调试模式下）
	if debug_mode and frame_counter % 1800 == 0:  # 每30秒（假设60FPS）
		var health_score = _calculate_system_health_score(get_performance_stats())
		_log_info("System health check", {"health_score": health_score})
		
		if health_score < 60:
			_log_warning("System health degraded", {
				"health_score": health_score,
				"suggestions_available": get_memory_optimization_suggestions().size()
			})

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

# 应用效果到目标 - 增强错误处理
func apply_effect(target: Node, effect_type: String, duration: float, stacks: int = 1) -> void:
	# 输入验证
	if not is_instance_valid(target):
		_log_error("Cannot apply effect to invalid target", {
			"effect_type": effect_type,
			"duration": duration,
			"stacks": stacks
		})
		return
	
	if effect_type.is_empty():
		_log_error("Cannot apply effect with empty effect_type", {
			"target": target.name if target.has_method("get") else "unknown",
			"duration": duration,
			"stacks": stacks
		})
		return
	
	if duration < 0:
		_log_warning("Negative duration for effect", {
			"effect_type": effect_type,
			"duration": duration,
			"target": target.name if target.has_method("get") else "unknown"
		})
		duration = 0.0
	
	if stacks <= 0:
		_log_warning("Invalid stack count for effect", {
			"effect_type": effect_type,
			"stacks": stacks,
			"target": target.name if target.has_method("get") else "unknown"
		})
		stacks = 1
	
	_log_info("Applying effect", {
		"effect_type": effect_type,
		"target": target.name if target.has_method("get") else "unknown",
		"duration": duration,
		"stacks": stacks
	})
	
	var start_time = Time.get_time_dict_from_system()
	
	# 检查是否已有相同类型的效果
	var existing_effect = find_effect_on_target(target, effect_type)
	
	if existing_effect:
		# 刷新持续时间并叠加层数
		existing_effect.refresh_duration(duration)
		existing_effect.add_stack(stacks)
		_log_info("Effect refreshed", {
			"effect_type": effect_type,
			"new_stacks": existing_effect.stacks,
			"new_duration": existing_effect.duration
		})
	else:
		# 创建新效果
		if not effect_pool:
			_log_error("Effect pool is null, cannot create effect", {
				"effect_type": effect_type,
				"target": target.name if target.has_method("get") else "unknown"
			})
			return
		
		var effect = effect_pool.get_effect(effect_type)
		if not effect:
			_log_error("Failed to get effect from pool", {
				"effect_type": effect_type,
				"pool_size": effect_pool.get_pool_size() if effect_pool else "null"
			})
			return
		
		effect.initialize(target, effect_type, duration, stacks)
		
		# 添加到对应频率组
		var frequency = EFFECT_UPDATE_FREQUENCY.get(effect_type, "mid_freq")
		if not effect_groups.has(frequency):
			_log_error("Invalid frequency group", {
				"effect_type": effect_type,
				"frequency": frequency
			})
			return
		
		effect_groups[frequency].append(effect)
		
		# 记录到目标效果表
		if not active_effects_by_target.has(target):
			active_effects_by_target[target] = []
		active_effects_by_target[target].append(effect)
		
		effect_applied.emit(target, effect_type)
		_log_info("New effect created", {
			"effect_type": effect_type,
			"frequency": frequency,
			"pool_size_after": effect_pool.get_pool_size() if effect_pool else "null"
		})
	
	# 性能监控
	var end_time = Time.get_time_dict_from_system()
	var duration_ms = (end_time.second * 1000 + end_time.millisecond) - (start_time.second * 1000 + start_time.millisecond)
	_log_performance("apply_effect", duration_ms, {
		"effect_type": effect_type,
		"existing_effect": existing_effect != null
	})

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
	game_paused = paused
	set_process(not paused)

# 详细的错误日志系统
var debug_mode: bool = false
var error_log: Array = []
var warning_log: Array = []
var performance_log: Array = []
var max_log_entries: int = 100

# 启用/禁用调试模式
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	if debug_mode:
		_log_info("GemEffectSystem: Debug mode enabled")

# 详细日志记录方法
func _log_error(message: String, context: Dictionary = {}) -> void:
	var log_entry = {
		"timestamp": Time.get_time_string_from_system(),
		"frame": frame_counter,
		"message": message,
		"context": context
	}
	error_log.append(log_entry)
	
	# 限制日志大小
	if error_log.size() > max_log_entries:
		error_log.pop_front()
	
	push_error("GemEffectSystem ERROR [Frame %d]: %s" % [frame_counter, message])
	if debug_mode and not context.is_empty():
		print("  Context: ", context)

func _log_warning(message: String, context: Dictionary = {}) -> void:
	var log_entry = {
		"timestamp": Time.get_time_string_from_system(),
		"frame": frame_counter,
		"message": message,
		"context": context
	}
	warning_log.append(log_entry)
	
	if warning_log.size() > max_log_entries:
		warning_log.pop_front()
	
	push_warning("GemEffectSystem WARNING [Frame %d]: %s" % [frame_counter, message])
	if debug_mode and not context.is_empty():
		print("  Context: ", context)

func _log_info(message: String, context: Dictionary = {}) -> void:
	if debug_mode:
		print("GemEffectSystem INFO [Frame %d]: %s" % [frame_counter, message])
		if not context.is_empty():
			print("  Context: ", context)

func _log_performance(operation: String, duration_ms: float, details: Dictionary = {}) -> void:
	var log_entry = {
		"timestamp": Time.get_time_string_from_system(),
		"frame": frame_counter,
		"operation": operation,
		"duration_ms": duration_ms,
		"details": details
	}
	performance_log.append(log_entry)
	
	if performance_log.size() > max_log_entries:
		performance_log.pop_front()
	
	if duration_ms > 1.0:  # 记录超过1ms的操作
		_log_warning("Slow operation detected: %s took %.3f ms" % [operation, duration_ms], details)

# 性能监控 - 增强版
func get_performance_stats() -> Dictionary:
	var total_effects = 0
	var effects_by_type = {}
	
	# 统计各组效果
	for group_name in effect_groups.keys():
		var group = effect_groups[group_name]
		total_effects += group.size()
		
		# 按类型统计效果
		for effect in group:
			var effect_type = effect.effect_type if effect.has_method("get") else "unknown"
			if not effects_by_type.has(effect_type):
				effects_by_type[effect_type] = 0
			effects_by_type[effect_type] += 1
	
	var cache_stats = {
		"enemy_cache_size": enemy_cache.size(),
		"tower_cache_size": tower_cache.size(),
		"cache_update_interval": enemy_cache_update_interval,
		"last_enemy_cache_update": frame_counter - enemy_cache_last_update,
		"last_tower_cache_update": frame_counter - tower_cache_last_update
	}
	
	var memory_stats = {
		"effect_pool_memory_mb": effect_pool._estimate_memory_usage() if effect_pool else 0.0,
		"cache_memory_estimate_kb": (enemy_cache.size() + tower_cache.size()) * 0.1,  # 粗略估算
		"active_targets": active_effects_by_target.size()
	}
	
	return {
		"total_effects": total_effects,
		"high_freq_effects": effect_groups["high_freq"].size(),
		"mid_freq_effects": effect_groups["mid_freq"].size(), 
		"low_freq_effects": effect_groups["low_freq"].size(),
		"targets_with_effects": active_effects_by_target.size(),
		"pooled_effects": effect_pool.get_pool_size() if effect_pool else 0,
		"effects_by_type": effects_by_type,
		"cache_stats": cache_stats,
		"memory_stats": memory_stats,
		"error_count": error_log.size(),
		"warning_count": warning_log.size(),
		"performance_issues": _count_performance_issues()
	}

func _count_performance_issues() -> int:
	var count = 0
	for entry in performance_log:
		if entry.duration_ms > 1.0:
			count += 1
	return count

# 内存监控系统
var memory_monitor_timer: float = 0.0
var memory_monitor_interval: float = 10.0  # 每10秒检查一次
var memory_history: Array = []
var max_memory_history: int = 60  # 保存10分钟历史（每10秒一次）

func _monitor_memory() -> void:
	memory_monitor_timer += get_process_delta_time()
	
	if memory_monitor_timer >= memory_monitor_interval:
		memory_monitor_timer = 0.0
		
		var memory_snapshot = _create_memory_snapshot()
		memory_history.append(memory_snapshot)
		
		# 限制历史记录数量
		if memory_history.size() > max_memory_history:
			memory_history.pop_front()
		
		# 检查内存趋势和警告
		_check_memory_warnings(memory_snapshot)

func _create_memory_snapshot() -> Dictionary:
	var stats = get_performance_stats()
	
	return {
		"timestamp": Time.get_time_string_from_system(),
		"frame": frame_counter,
		"total_effects": stats.total_effects,
		"active_targets": stats.targets_with_effects,
		"pool_memory_mb": stats.memory_stats.effect_pool_memory_mb,
		"cache_memory_kb": stats.memory_stats.cache_memory_estimate_kb,
		"enemy_cache_size": stats.cache_stats.enemy_cache_size,
		"tower_cache_size": stats.cache_stats.tower_cache_size,
		"error_count": stats.error_count,
		"warning_count": stats.warning_count,
		"performance_issues": stats.performance_issues
	}

func _check_memory_warnings(snapshot: Dictionary) -> void:
	# 检查内存使用过高
	if snapshot.pool_memory_mb > 10.0:  # 超过10MB
		_log_warning("High memory usage detected", {
			"pool_memory_mb": snapshot.pool_memory_mb,
			"total_effects": snapshot.total_effects
		})
	
	# 检查错误增长趋势
	if memory_history.size() >= 3:
		var prev_snapshot = memory_history[memory_history.size() - 2]
		var error_increase = snapshot.error_count - prev_snapshot.error_count
		
		if error_increase > 5:  # 10秒内超过5个新错误
			_log_warning("High error rate detected", {
				"error_increase": error_increase,
				"total_errors": snapshot.error_count
			})
	
	# 检查内存泄漏趋势
	if memory_history.size() >= 6:  # 至少1分钟历史
		var memory_trend = _analyze_memory_trend()
		if memory_trend.slope > 0.5:  # 每10秒增长0.5MB
			_log_warning("Potential memory leak detected", {
				"memory_trend_slope": memory_trend.slope,
				"current_memory_mb": snapshot.pool_memory_mb
			})

func _analyze_memory_trend() -> Dictionary:
	if memory_history.size() < 3:
		return {"slope": 0.0, "correlation": 0.0}
	
	var recent_history = memory_history.slice(-6)  # 最近6次记录
	var n = recent_history.size()
	var sum_x = 0.0
	var sum_y = 0.0
	var sum_xy = 0.0
	var sum_x2 = 0.0
	
	for i in range(n):
		var x = float(i)
		var y = recent_history[i].pool_memory_mb
		sum_x += x
		sum_y += y
		sum_xy += x * y
		sum_x2 += x * x
	
	# 计算线性回归斜率
	var denominator = n * sum_x2 - sum_x * sum_x
	var slope = 0.0
	if denominator != 0:
		slope = (n * sum_xy - sum_x * sum_y) / denominator
	
	return {"slope": slope, "samples": n}

# 内存优化建议
func get_memory_optimization_suggestions() -> Array:
	var suggestions = []
	var stats = get_performance_stats()
	
	# 基于当前状态生成建议
	if stats.memory_stats.effect_pool_memory_mb > 5.0:
		suggestions.append({
			"type": "memory",
			"message": "Consider reducing effect pool max size or implementing more aggressive cleanup",
			"priority": "high"
		})
	
	if stats.cache_stats.enemy_cache_size > 200:
		suggestions.append({
			"type": "cache",
			"message": "Large enemy cache detected, consider reducing cache update interval",
			"priority": "medium"
		})
	
	if stats.performance_issues > 10:
		suggestions.append({
			"type": "performance",
			"message": "Multiple performance issues detected, review effect processing frequency",
			"priority": "high"
		})
	
	if stats.error_count > 50:
		suggestions.append({
			"type": "stability",
			"message": "High error count, review error logs for recurring issues",
			"priority": "critical"
		})
	
	return suggestions

# 生成内存报告
func generate_memory_report() -> Dictionary:
	var stats = get_performance_stats()
	var suggestions = get_memory_optimization_suggestions()
	var trend = _analyze_memory_trend() if memory_history.size() >= 3 else {"slope": 0.0}
	
	return {
		"current_stats": stats,
		"memory_history": memory_history,
		"memory_trend": trend,
		"optimization_suggestions": suggestions,
		"health_score": _calculate_system_health_score(stats)
	}

func _calculate_system_health_score(stats: Dictionary) -> int:
	var score = 100
	
	# 内存使用扣分
	if stats.memory_stats.effect_pool_memory_mb > 10.0:
		score -= 30
	elif stats.memory_stats.effect_pool_memory_mb > 5.0:
		score -= 15
	
	# 错误扣分
	if stats.error_count > 50:
		score -= 25
	elif stats.error_count > 20:
		score -= 10
	
	# 性能问题扣分
	if stats.performance_issues > 10:
		score -= 20
	elif stats.performance_issues > 5:
		score -= 10
	
	# 确保分数在0-100范围内
	return max(0, min(100, score))

# 调试信息 - 全面升级版
func print_debug_info() -> void:
	var stats = get_performance_stats()
	var health_score = _calculate_system_health_score(stats)
	var suggestions = get_memory_optimization_suggestions()
	
	print("\n=== GemEffectSystem Debug Report ===")
	print("System Health Score: %d/100" % health_score)
	print("\nEffect Statistics:")
	print("  Total Effects: %d" % stats.total_effects)
	print("  High Freq: %d" % stats.high_freq_effects)
	print("  Mid Freq: %d" % stats.mid_freq_effects)
	print("  Low Freq: %d" % stats.low_freq_effects)
	print("  Affected Targets: %d" % stats.targets_with_effects)
	
	print("\nMemory Usage:")
	print("  Effect Pool: %.2f MB" % stats.memory_stats.effect_pool_memory_mb)
	print("  Cache: %.2f KB" % stats.memory_stats.cache_memory_estimate_kb)
	
	print("\nCache Statistics:")
	print("  Enemy Cache: %d entities" % stats.cache_stats.enemy_cache_size)
	print("  Tower Cache: %d entities" % stats.cache_stats.tower_cache_size)
	print("  Last Enemy Update: %d frames ago" % stats.cache_stats.last_enemy_cache_update)
	
	print("\nSystem Issues:")
	print("  Errors: %d" % stats.error_count)
	print("  Warnings: %d" % stats.warning_count)
	print("  Performance Issues: %d" % stats.performance_issues)
	
	if not suggestions.is_empty():
		print("\nOptimization Suggestions:")
		for suggestion in suggestions:
			print("  [%s] %s" % [suggestion.priority.to_upper(), suggestion.message])
	
	print("=".repeat(40))

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

# 缓存管理方法

# 更新敌人缓存
func _update_enemy_cache() -> void:
	if frame_counter - enemy_cache_last_update >= enemy_cache_update_interval:
		var tree = get_tree()
		if not tree or not tree.current_scene:
			enemy_cache.clear()
			return
		
		# 获取所有敌人并过滤有效的
		var all_enemies = tree.current_scene.get_tree().get_nodes_in_group("enemy")
		enemy_cache.clear()
		
		for enemy in all_enemies:
			if is_instance_valid(enemy) and enemy.has_method("global_position"):
				enemy_cache.append(enemy)
		
		enemy_cache_last_update = frame_counter

# 更新塔缓存
func _update_tower_cache() -> void:
	if frame_counter - tower_cache_last_update >= enemy_cache_update_interval:
		var tree = get_tree()
		if not tree or not tree.current_scene:
			tower_cache.clear()
			return
		
		var all_towers = tree.current_scene.get_tree().get_nodes_in_group("tower")
		tower_cache.clear()
		
		for tower in all_towers:
			if is_instance_valid(tower) and tower.has_method("global_position"):
				tower_cache.append(tower)
		
		tower_cache_last_update = frame_counter

# 优化版：获取区域内的敌人
func get_enemies_in_area(center: Vector2, radius: float) -> Array:
	# 更新敌人缓存
	_update_enemy_cache()
	
	var enemies = []
	var radius_squared = radius * radius  # 使用平方距离避免开方计算
	
	for enemy in enemy_cache:
		if is_instance_valid(enemy):
			var distance_squared = enemy.global_position.distance_squared_to(center)
			if distance_squared <= radius_squared:
				enemies.append(enemy)
	
	return enemies

# 获取区域内的塔
func get_towers_in_area(center: Vector2, radius: float) -> Array:
	_update_tower_cache()
	
	var towers = []
	var radius_squared = radius * radius
	
	for tower in tower_cache:
		if is_instance_valid(tower):
			var distance_squared = tower.global_position.distance_squared_to(center)
			if distance_squared <= radius_squared:
				towers.append(tower)
	
	return towers

# 快速查找最近的敌人
func get_nearest_enemy(center: Vector2, max_range: float = INF) -> Node:
	_update_enemy_cache()
	
	var nearest_enemy = null
	var nearest_distance_squared = max_range * max_range
	
	for enemy in enemy_cache:
		if is_instance_valid(enemy):
			var distance_squared = enemy.global_position.distance_squared_to(center)
			if distance_squared < nearest_distance_squared:
				nearest_distance_squared = distance_squared
				nearest_enemy = enemy
	
	return nearest_enemy

# 批量区域查找优化
func get_enemies_in_multiple_areas(areas: Array) -> Dictionary:
	_update_enemy_cache()
	
	var results = {}
	for i in range(areas.size()):
		results[i] = []
	
	# 一次遍历处理所有区域
	for enemy in enemy_cache:
		if not is_instance_valid(enemy):
			continue
			
		var enemy_pos = enemy.global_position
		for i in range(areas.size()):
			var area = areas[i]
			var center = area.center
			var radius_squared = area.radius * area.radius
			
			if enemy_pos.distance_squared_to(center) <= radius_squared:
				results[i].append(enemy)
	
	return results

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
	var towers = get_towers_in_area(center, radius)
	for tower in towers:
		if tower != self and tower.has_method("apply_attack_speed_bonus"):
			tower.apply_attack_speed_bonus(speed_bonus)

# 移除攻击速度光环效果
func remove_attack_speed_aura(center: Vector2, radius: float) -> void:
	var towers = get_towers_in_area(center, radius)
	for tower in towers:
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
	var towers = get_towers_in_area(center, radius)
	for tower in towers:
		if tower != self and tower.has_method("heal"):
			tower.heal(heal_amount)

# 应用能量返还到友方塔
func restore_energy_to_towers(center: Vector2, radius: float, energy_amount: float) -> void:
	var towers = get_towers_in_area(center, radius)
	for tower in towers:
		if tower != self and tower.has_method("restore_energy"):
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

## Hero System Integration
## Enhanced methods to support hero-specific effects and mechanics

# Apply effect specifically to heroes
func apply_effect_to_hero(hero: HeroBase, effect_type: String, duration: float, stacks: int = 1) -> void:
	"""Apply effect specifically to heroes with hero-specific handling"""
	if not is_instance_valid(hero):
		_log_error("Cannot apply effect to invalid hero", {
			"effect_type": effect_type,
			"duration": duration,
			"stacks": stacks
		})
		return
	
	# Apply hero-specific effect modifications
	var modified_duration = duration
	var modified_stacks = stacks
	
	# Hero resistance/vulnerability to certain effects
	match effect_type:
		"burn":
			if hero.element == "fire":
				# Fire heroes take reduced burn damage and duration
				modified_duration *= 0.5
				modified_stacks = max(1, stacks - 1)
		"freeze":
			if hero.element == "ice":
				# Ice heroes are immune to freeze
				return
			else:
				# Heroes have general freeze resistance
				modified_duration *= 0.7
		"stun":
			# Heroes have stun resistance
			modified_duration *= 0.6
		"silence":
			# Silence affects hero skill casting
			hero.skill_charge_paused = true
		"invulnerable":
			# Heroes can be made invulnerable during skills
			pass
	
	# Apply the effect using existing system
	apply_effect(hero, effect_type, modified_duration, modified_stacks)
	
	# Log hero-specific effect application
	_log_info("Hero effect applied", {
		"hero_type": hero.hero_type,
		"hero_name": hero.hero_name,
		"effect_type": effect_type,
		"original_duration": duration,
		"modified_duration": modified_duration,
		"stacks": modified_stacks
	})

# Get heroes in area (similar to enemies)
func get_heroes_in_area(center: Vector2, radius: float) -> Array:
	"""Get heroes within specified area"""
	_update_hero_cache()
	
	var heroes = []
	var radius_squared = radius * radius
	
	for hero in hero_cache:
		if is_instance_valid(hero):
			var distance_squared = hero.global_position.distance_squared_to(center)
			if distance_squared <= radius_squared:
				heroes.append(hero)
	
	return heroes

# Update hero cache
func _update_hero_cache() -> void:
	"""Update hero cache for area queries"""
	if frame_counter - hero_cache_last_update >= enemy_cache_update_interval:
		var tree = get_tree()
		if not tree or not tree.current_scene:
			hero_cache.clear()
			return
		
		var all_heroes = tree.current_scene.get_tree().get_nodes_in_group("heroes")
		hero_cache.clear()
		
		for hero in all_heroes:
			if is_instance_valid(hero) and hero.has_method("global_position"):
				hero_cache.append(hero)
		
		hero_cache_last_update = frame_counter

# Apply aura effects to heroes
func apply_hero_aura(center: Vector2, radius: float, effect_type: String, caster: Node = null) -> void:
	"""Apply aura effects to heroes in range"""
	var heroes = get_heroes_in_area(center, radius)
	for hero in heroes:
		# Don't apply self-cast auras to the caster
		if caster and hero == caster:
			continue
		
		match effect_type:
			"flame_aura":
				apply_flame_aura_to_hero(hero, caster)
			"enhanced_flame_aura":
				apply_enhanced_flame_aura_to_hero(hero, caster)
			"healing_aura":
				apply_healing_aura_to_hero(hero)
			"buff_aura":
				apply_buff_aura_to_hero(hero, caster)

func apply_flame_aura_to_hero(hero: HeroBase, caster: HeroBase) -> void:
	"""Apply flame aura effects to hero"""
	if not hero or not caster:
		return
	
	var aura_radius = caster.get_meta("flame_aura_radius", 200.0)
	var aura_damage = caster.get_meta("flame_aura_damage", 30.0)
	
	# Heroes don't take damage from friendly auras, but get buffs instead
	# Apply fire damage bonus
	if not hero.get_meta("flame_aura_active", false):
		hero.set_meta("flame_aura_active", true)
		hero.set_meta("flame_aura_damage_bonus", aura_damage * 0.1) # 10% of aura damage as bonus

func apply_enhanced_flame_aura_to_hero(hero: HeroBase, caster: HeroBase) -> void:
	"""Apply enhanced flame aura effects to hero"""
	if not hero or not caster:
		return
	
	var aura_radius = caster.get_meta("enhanced_aura_radius", 250.0)
	var aura_damage = caster.get_meta("enhanced_aura_damage", 65.0)
	var burn_stacks = caster.get_meta("enhanced_aura_burn_stacks", 3)
	
	# Enhanced aura gives bigger bonuses
	if not hero.get_meta("enhanced_flame_aura_active", false):
		hero.set_meta("enhanced_flame_aura_active", true)
		hero.set_meta("enhanced_flame_damage_bonus", aura_damage * 0.15)
		# Also increase attack speed
		hero.current_stats["attack_speed"] *= 1.1

func apply_healing_aura_to_hero(hero: HeroBase) -> void:
	"""Apply healing aura to hero"""
	if not hero or not hero.is_alive:
		return
	
	var healing_amount = 50.0 # Base healing per second
	
	if hero.health_bar and hero.health_bar.value < hero.health_bar.max_value:
		hero.health_bar.value = min(hero.health_bar.max_value, hero.health_bar.value + healing_amount)

func apply_buff_aura_to_hero(hero: HeroBase, caster: HeroBase) -> void:
	"""Apply general buff aura to hero"""
	if not hero or not caster:
		return
	
	# Apply temporary stat bonuses
	hero.da_bonus += 0.1 # 10% damage amplification
	hero.charge_generation_rate *= 1.1 # 10% faster charge

# Process hero-specific effects
func process_hero_effects(hero: HeroBase, delta: float) -> void:
	"""Process ongoing effects specific to heroes"""
	if not hero or not hero.is_alive:
		return
	
	var hero_effects = get_effects_on_target(hero)
	
	for effect in hero_effects:
		process_individual_hero_effect(hero, effect, delta)

func process_individual_hero_effect(hero: HeroBase, effect: StatusEffect, delta: float) -> void:
	"""Process individual hero effect"""
	match effect.effect_type:
		"burn":
			process_hero_burn_effect(hero, effect, delta)
		"freeze":
			process_hero_freeze_effect(hero, effect)
		"stun":
			process_hero_stun_effect(hero, effect)
		"silence":
			process_hero_silence_effect(hero, effect)
		"flame_armor":
			process_flame_armor_effect(hero, effect, delta)

func process_hero_burn_effect(hero: HeroBase, effect: StatusEffect, delta: float) -> void:
	"""Process burn effect on hero"""
	var damage_per_second = 20.0 * effect.stacks
	var damage_this_tick = damage_per_second * delta
	
	# Apply burn damage
	if hero.health_bar:
		hero.health_bar.value = max(0, hero.health_bar.value - damage_this_tick)
		
		# Check for hero death
		if hero.health_bar.value <= 0 and hero.is_alive:
			hero.die()

func process_hero_freeze_effect(hero: HeroBase, effect: StatusEffect) -> void:
	"""Process freeze effect on hero"""
	# Freeze slows down hero actions
	hero.skill_charge_paused = true
	hero.current_stats["attack_speed"] *= 0.1 # Very slow attacks

func process_hero_stun_effect(hero: HeroBase, effect: StatusEffect) -> void:
	"""Process stun effect on hero"""
	# Stun completely disables hero
	hero.skill_charge_paused = true
	hero.attack_target = null # Clear current target

func process_hero_silence_effect(hero: HeroBase, effect: StatusEffect) -> void:
	"""Process silence effect on hero"""
	# Silence prevents skill usage but allows basic attacks
	hero.skill_charge_paused = true
	# Clear any queued skills
	hero.skill_queue.clear()

func process_flame_armor_effect(hero: HeroBase, effect: StatusEffect, delta: float) -> void:
	"""Process flame armor effect"""
	var aura_radius = effect.data.get("aura_radius", 200.0)
	var aura_damage = effect.data.get("aura_damage", 30.0)
	
	# Apply aura damage to nearby enemies
	var enemies = get_enemies_in_area(hero.global_position, aura_radius)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(aura_damage * delta, "fire")

# Enhanced performance stats for hero effects
func get_hero_performance_stats() -> Dictionary:
	"""Get performance statistics including hero effects"""
	var base_stats = get_performance_stats()
	
	var hero_stats = {
		"hero_cache_size": hero_cache.size(),
		"last_hero_cache_update": frame_counter - hero_cache_last_update,
		"heroes_with_effects": 0,
		"hero_effects_by_type": {}
	}
	
	# Count hero effects
	for target in active_effects_by_target:
		if target is HeroBase:
			hero_stats.heroes_with_effects += 1
			var target_effects = active_effects_by_target[target]
			for effect in target_effects:
				var effect_type = effect.effect_type
				if not hero_stats.hero_effects_by_type.has(effect_type):
					hero_stats.hero_effects_by_type[effect_type] = 0
				hero_stats.hero_effects_by_type[effect_type] += 1
	
	base_stats["hero_stats"] = hero_stats
	return base_stats

# Hero-specific effect cleanup
func clear_hero_aura_effects(hero: HeroBase) -> void:
	"""Clear aura effects from hero when out of range"""
	if not hero:
		return
	
	# Remove aura bonuses
	hero.remove_meta("flame_aura_active")
	hero.remove_meta("flame_aura_damage_bonus")
	hero.remove_meta("enhanced_flame_aura_active")
	hero.remove_meta("enhanced_flame_damage_bonus")
	
	# Reset DA bonus (this could be more sophisticated)
	hero.da_bonus = 0.0

# Skill-based effect application
func apply_skill_area_effect(skill: HeroSkill, center: Vector2, caster: HeroBase) -> void:
	"""Apply area effects for hero skills"""
	if not skill or not caster:
		return
	
	var effect_radius = skill.get_area_of_effect()
	if effect_radius <= 0:
		return
	
	match skill.skill_id:
		"shadow_strike":
			apply_shadow_strike_effects(center, effect_radius, caster)
		"flame_armor":
			apply_flame_armor_skill_effects(caster)
		"flame_phantom":
			apply_flame_phantom_effects(center, caster)

func apply_shadow_strike_effects(center: Vector2, radius: float, caster: HeroBase) -> void:
	"""Apply Shadow Strike skill effects"""
	var enemies = get_enemies_in_area(center, radius)
	var damage = caster.current_stats.get("damage", 0) * 1.5 # 50% more damage
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, caster.element)
		
		# Apply minor stun
		apply_effect_to_hero(enemy, "stun", 0.5, 1)

func apply_flame_armor_skill_effects(caster: HeroBase) -> void:
	"""Apply Flame Armor skill effects"""
	# Apply flame armor effect to caster
	apply_effect_to_hero(caster, "flame_armor", 15.0, 1)
	
	# Set up aura data
	caster.set_meta("flame_aura_radius", 200.0)
	caster.set_meta("flame_aura_damage", 30.0)

func apply_flame_phantom_effects(center: Vector2, caster: HeroBase) -> void:
	"""Apply Flame Phantom skill effects"""
	# Enhanced flame aura
	caster.set_meta("enhanced_aura_radius", 250.0)
	caster.set_meta("enhanced_aura_damage", 65.0)
	caster.set_meta("enhanced_aura_burn_stacks", 3)
	
	# Apply burn to all enemies in area
	var enemies = get_enemies_in_area(center, 250.0)
	for enemy in enemies:
		apply_effect(enemy, "burn", 5.0, 3)