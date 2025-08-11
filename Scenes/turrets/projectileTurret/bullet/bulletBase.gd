extends Node2D

var bullet_type := "":
	set(value):
		bullet_type = value
		$AnimatedSprite2D.sprite_frames = load(Data.bullets[value]["frames"])

var target = null
var direction: Vector2

# 基础属性
var speed: float = 400.0
var base_damage: float = 10  # 基础伤害
var damage: float = 10       # 计算后的实际伤害
var pierce: int = 1
var time: float = 1.0

# 元素和增强属性
var element: String = "neutral"
var turret_category: String = ""
var equipped_gem: Dictionary = {}

func _process(delta):
	if target:
		if not direction: 
			direction= (target - position).normalized()
		position += direction * speed * delta

func _on_area_2d_area_entered(area):
	var obj = area.get_parent()
	if obj.is_in_group("enemy"):
		pierce -= 1
		
		# 计算增强后的伤害
		var target_element = "neutral"
		if obj.has_method("get_element"):
			target_element = obj.get_element()
		
		# 使用增强的伤害计算
		var final_damage = calculate_enhanced_damage(target_element)
		obj.get_damage(final_damage)
		
	if pierce == 0:
		queue_free()

func calculate_enhanced_damage(target_element: String) -> float:
	var final_damage = base_damage
	
	# 获取武器盘管理器
	var weapon_manager = get_weapon_wheel_manager()
	if not weapon_manager:
		return final_damage
	
	# 应用炮塔类型BUFF (加算)
	var turret_buff_multiplier = weapon_manager.calculate_turret_multiplier(turret_category)
	
	# 应用元素BUFF (加算)
	var element_buff_multiplier = weapon_manager.calculate_element_multiplier(element)
		
	# 应用宝石加成 (加算到元素BUFF)
	if equipped_gem.has("damage_bonus"):
		element_buff_multiplier += equipped_gem.damage_bonus
	
	# 应用属性克制 (乘算)
	var effectiveness = ElementSystem.get_effectiveness_multiplier(element, target_element)
	
	# 最终计算：基础伤害 × 炮塔类型BUFF × 元素BUFF × 属性克制
	final_damage = base_damage * turret_buff_multiplier * element_buff_multiplier * effectiveness
	
	return final_damage

func get_weapon_wheel_manager() -> WeaponWheelManager:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("WeaponWheelManager") as WeaponWheelManager
	return null

func _on_disappear_timer_timeout():
	queue_free()
