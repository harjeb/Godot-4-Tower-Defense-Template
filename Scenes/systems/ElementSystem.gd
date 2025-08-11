extends Node

# 计算属性克制伤害倍率
static func get_effectiveness_multiplier(attacker_element: String, defender_element: String) -> float:
	if attacker_element in Data.element_effectiveness:
		var effectiveness = Data.element_effectiveness[attacker_element]
		if defender_element in effectiveness.strong_against:
			return 1.5  # +50%伤害
		elif defender_element in effectiveness.weak_against:
			return 0.75  # -25%伤害
	return 1.0  # 正常伤害

# 计算元素BUFF加成
static func get_element_buff(element: String, buffs: Array) -> float:
	var total_bonus = 0.0
	for buff in buffs:
		if buff.has("element_type") and buff.element_type == element:
			total_bonus += buff.bonus
	return total_bonus

# 宝石合成逻辑
static func can_craft_gem(gem_type: String, level: int, inventory: Array) -> bool:
	if level >= 3:
		return false
	var required_gem = gem_type + "_" + get_level_name(level)
	var count = 0
	for item in inventory:
		if item.id == required_gem:
			count += 1
	return count >= 2

static func get_level_name(level: int) -> String:
	match level:
		1: return "basic"
		2: return "intermediate" 
		3: return "advanced"
		_: return "basic"

# 获取元素颜色
static func get_element_color(element: String) -> Color:
	if element in Data.elements:
		return Data.elements[element].color
	return Color.WHITE

# 检查宝石是否存在
static func is_valid_gem(gem_id: String) -> bool:
	return gem_id in Data.gems

# 获取宝石的元素类型
static func get_gem_element(gem_id: String) -> String:
	if gem_id in Data.gems:
		return Data.gems[gem_id].element
	return "neutral"

# 获取下一级宝石ID
static func get_next_level_gem(gem_id: String) -> String:
	if gem_id in Data.gems:
		var gem_data = Data.gems[gem_id]
		var element = gem_data.element
		var level = gem_data.level
		if level < 3:
			return element + "_" + get_level_name(level + 1)
	return ""
