extends Node
class_name EffectPool

## 效果对象池系统
## 用于优化StatusEffect的创建和回收，减少GC压力

var effect_pool: Dictionary = {}
var pool_size: int = 0
var max_pool_size: int = 200

# 预定义的效果类型
const EFFECT_TYPES = [
	"burn", "frost", "freeze", "shock", "corruption", 
	"armor_break", "slow", "stun", "silence", "petrify",
	"paralysis", "knockback", "life_steal"
]

func _ready() -> void:
	# 预创建一些常用效果
	_preallocate_effects()

func _preallocate_effects() -> void:
	for effect_type in EFFECT_TYPES:
		var count = 10  # 每种类型预创建10个
		for i in range(count):
			var effect = StatusEffect.new()
			effect_pool[effect] = false  # false表示在池中，可用
			pool_size += 1

# 从对象池获取效果
func get_effect(effect_type: String) -> StatusEffect:
	# 查找可用的效果
	for effect in effect_pool.keys():
		if effect_pool[effect] == false:
			effect_pool[effect] = true  # 标记为已使用
			pool_size -= 1
			return effect
	
	# 如果没有可用的效果，创建新的
	if effect_pool.size() < max_pool_size:
		var new_effect = StatusEffect.new()
		effect_pool[new_effect] = true
		return new_effect
	
	# 如果达到最大池大小，返回一个新的效果（不加入池）
	push_warning("Effect pool full, creating new effect without pooling")
	return StatusEffect.new()

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

# 性能优化：定期清理过大的池
func _on_pool_cleanup_timeout() -> void:
	if effect_pool.size() > 100:  # 如果池太大
		var to_remove = []
		for effect in effect_pool.keys():
			if effect_pool[effect] == false:  # 只移除未使用的
				to_remove.append(effect)
				if to_remove.size() >= 20:  # 一次移除20个
					break
		
		for effect in to_remove:
			effect_pool.erase(effect)
			if is_instance_valid(effect):
				effect.call_deferred("free")

# 调试信息
func get_debug_info() -> Dictionary:
	return {
		"pool_size": pool_size,
		"total_allocated": effect_pool.size(),
		"active_effects": get_active_effects_count(),
		"max_pool_size": max_pool_size
	}