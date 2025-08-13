extends Node
class_name EffectPool

## 效果对象池系统
## 用于优化StatusEffect的创建和回收，减少GC压力

var effect_pool: Dictionary = {}
var pool_size: int = 0
var max_pool_size: int = 200

# 预定义的效果类型 - 扩展到包含所有五元素效果
const EFFECT_TYPES = [
	# 基础效果
	"burn", "frost", "freeze", "shock", "corruption", 
	"armor_break", "slow", "stun", "silence", "petrify",
	"paralysis", "knockback", "life_steal",
	
	# 五元素扩展效果
	"weight", "imbalance", "blind", "purify", "judgment",
	"corrosion", "fear", "life_drain", "aura_damage", 
	"aura_speed", "passive_regen", "environmental"
]

func _ready() -> void:
	# 预创建一些常用效果
	_preallocate_effects()
	
	# 设置定期清理定时器
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 60.0  # 每60秒清理一次
	cleanup_timer.timeout.connect(_on_pool_cleanup_timeout)
	cleanup_timer.autostart = true
	add_child(cleanup_timer)

func _preallocate_effects() -> void:
	var common_effects = ["burn", "frost", "slow", "armor_break", "shock"]
	var rare_effects = ["freeze", "petrify", "judgment", "fear", "life_drain"]
	
	# 常用效果预创建更多
	for effect_type in common_effects:
		for i in range(15):  # 常用效果预创建15个
			var effect = StatusEffect.new()
			effect_pool[effect] = false
			pool_size += 1
	
	# 稀有效果预创建较少
	for effect_type in rare_effects:
		for i in range(5):  # 稀有效果预创建5个
			var effect = StatusEffect.new()
			effect_pool[effect] = false
			pool_size += 1
	
	# 其他效果预创建中等数量
	var other_effects = []
	for effect_type in EFFECT_TYPES:
		if effect_type not in common_effects and effect_type not in rare_effects:
			other_effects.append(effect_type)
	
	for effect_type in other_effects:
		for i in range(8):  # 其他效果预创建8个
			var effect = StatusEffect.new()
			effect_pool[effect] = false
			pool_size += 1

# 从对象池获取效果 - 改进的实现
func get_effect(effect_type: String) -> StatusEffect:
	# 优化：使用数组而不是字典遍历，提升查找效率
	var available_effects = []
	for effect in effect_pool.keys():
		if effect_pool[effect] == false:
			available_effects.append(effect)
			if available_effects.size() >= 5:  # 限制搜索深度
				break
	
	# 如果找到可用效果，使用第一个
	if not available_effects.is_empty():
		var effect = available_effects[0]
		effect_pool[effect] = true  # 标记为已使用
		pool_size -= 1
		
		# 记录获取统计（用于性能监控）
		_record_effect_usage(effect_type)
		return effect
	
	# 如果没有可用效果且池未满，创建新的
	if effect_pool.size() < max_pool_size:
		var new_effect = StatusEffect.new()
		effect_pool[new_effect] = true
		_record_effect_creation(effect_type)
		return new_effect
	
	# 池已满，强制回收最老的已使用效果
	var forced_effect = _force_recycle_oldest_effect()
	if forced_effect:
		push_warning("Effect pool full, force recycling oldest effect for type: %s" % effect_type)
		return forced_effect
	
	# 最后手段：创建不入池的临时效果
	push_error("Effect pool critical: creating temporary effect for type: %s" % effect_type)
	var temp_effect = StatusEffect.new()
	_record_temp_effect_creation(effect_type)
	return temp_effect

# 回收效果到对象池
func return_effect(effect: StatusEffect) -> void:
	if effect_pool.has(effect):
		if effect_pool[effect] == true:  # 确保是正在使用的效果
			effect.reset()  # 重置效果状态
			effect_pool[effect] = false  # 标记为可用
			pool_size += 1
	else:
		# 如果效果不在池中，尝试加入池
		if effect_pool.size() < max_pool_size:
			effect.reset()
			effect_pool[effect] = false
			pool_size += 1
		else:
			# 池已满，直接释放
			effect.call_deferred("free")

# 清理对象池
func clear_pool() -> void:
	for effect in effect_pool.keys():
		if is_instance_valid(effect):
			effect.call_deferred("free")
	effect_pool.clear()
	pool_size = 0

# 获取池大小统计
func get_pool_size() -> int:
	return pool_size

func get_total_pool_size() -> int:
	return effect_pool.size()

func get_active_effects_count() -> int:
	var active_count = 0
	for in_use in effect_pool.values():
		if in_use:
			active_count += 1
	return active_count

# 性能优化：定期清理过大的池 - 增强版
func _on_pool_cleanup_timeout() -> void:
	last_cleanup_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	print("EffectPool: Starting cleanup cycle...")
	
	# 清理无效引用
	_cleanup_invalid_effects()
	
	# 如果池太大，进行清理
	if effect_pool.size() > 100:
		var to_remove = []
		var unused_count = 0
		
		for effect in effect_pool.keys():
			if effect_pool[effect] == false:  # 只移除未使用的
				to_remove.append(effect)
				unused_count += 1
				if to_remove.size() >= 30:  # 一次移除30个
					break
		
		print("EffectPool: Found %d unused effects, removing %d" % [unused_count, to_remove.size()])
		
		for effect in to_remove:
			effect_pool.erase(effect)
			if is_instance_valid(effect):
				effect.call_deferred("free")
	
	# 内存压力检查
	var estimated_memory = _estimate_memory_usage()
	if estimated_memory > 5.0:  # 如果超过5MB
		push_warning("EffectPool memory usage high: %.2f MB" % estimated_memory)
	
	# 打印简要统计
	print("EffectPool: Cleanup complete. Pool size: %d, Active: %d, Memory: %.2f MB" % [
		effect_pool.size(), get_active_effects_count(), estimated_memory
	])

# 性能统计变量
var effect_usage_stats: Dictionary = {}
var effect_creation_stats: Dictionary = {}
var temp_effect_count: int = 0
var last_cleanup_time: float = 0.0

# 记录效果使用统计
func _record_effect_usage(effect_type: String) -> void:
	if not effect_usage_stats.has(effect_type):
		effect_usage_stats[effect_type] = 0
	effect_usage_stats[effect_type] += 1

# 记录效果创建统计
func _record_effect_creation(effect_type: String) -> void:
	if not effect_creation_stats.has(effect_type):
		effect_creation_stats[effect_type] = 0
	effect_creation_stats[effect_type] += 1

# 记录临时效果创建
func _record_temp_effect_creation(effect_type: String) -> void:
	temp_effect_count += 1
	push_warning("Temporary effect created for type: %s (total temp effects: %d)" % [effect_type, temp_effect_count])

# 强制回收最老的已使用效果
func _force_recycle_oldest_effect() -> StatusEffect:
	for effect in effect_pool.keys():
		if effect_pool[effect] == true and is_instance_valid(effect):
			# 强制重置并回收
			effect.reset()
			effect_pool[effect] = false
			pool_size += 1
			return effect
	return null

# 内存优化：检查并清理无效引用
func _cleanup_invalid_effects() -> void:
	var to_remove = []
	for effect in effect_pool.keys():
		if not is_instance_valid(effect):
			to_remove.append(effect)
	
	for effect in to_remove:
		effect_pool.erase(effect)
		push_warning("Removed invalid effect from pool")

# 调试信息 - 增强版
func get_debug_info() -> Dictionary:
	_cleanup_invalid_effects()  # 清理无效引用
	
	return {
		"pool_size": pool_size,
		"total_allocated": effect_pool.size(),
		"active_effects": get_active_effects_count(),
		"max_pool_size": max_pool_size,
		"usage_stats": effect_usage_stats,
		"creation_stats": effect_creation_stats,
		"temp_effects_created": temp_effect_count,
		"last_cleanup": last_cleanup_time,
		"memory_usage_mb": _estimate_memory_usage()
	}

# 估算内存使用
func _estimate_memory_usage() -> float:
	var estimated_size_per_effect = 0.5  # KB per StatusEffect
	return effect_pool.size() * estimated_size_per_effect / 1024.0  # Convert to MB

# 性能报告
func print_performance_report() -> void:
	var debug_info = get_debug_info()
	print("=== EffectPool Performance Report ===")
	print("Pool Size: %d/%d" % [debug_info.active_effects, debug_info.max_pool_size])
	print("Total Allocated: %d" % debug_info.total_allocated)
	print("Estimated Memory: %.2f MB" % debug_info.memory_usage_mb)
	print("Temp Effects Created: %d" % debug_info.temp_effects_created)
	print("Most Used Effects:")
	
	var sorted_usage = []
	for effect_type in debug_info.usage_stats.keys():
		sorted_usage.append([effect_type, debug_info.usage_stats[effect_type]])
	
	sorted_usage.sort_custom(func(a, b): return a[1] > b[1])
	for i in range(min(5, sorted_usage.size())):
		print("  %s: %d times" % [sorted_usage[i][0], sorted_usage[i][1]])