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
var source_tower: Node = null  # 发射这个子弹的塔
var gem_effects: Array = []      # 宝石效果列表

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
		
		# 应用宝石效果
		_apply_gem_effects(obj)
		
		# 通知充能系统命中了敌人（只有非充能技能投射物才增加充能）
		if source_tower and not has_meta("is_charge_ability"):
			var charge_system = get_charge_system()
			if charge_system:
				charge_system.add_charge_on_hit(source_tower)
		
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

func get_weapon_wheel_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("WeaponWheelManager")
	return null

func get_charge_system() -> Node:
	var tree = get_tree()
	if tree and tree.current_scene:
		return tree.current_scene.get_node_or_null("ChargeSystem")
	return null

func _on_disappear_timer_timeout():
	queue_free()

# 宝石效果应用系统
func _apply_gem_effects(target: Node):
	if gem_effects.is_empty():
		return
	
	var effect_manager = get_effect_manager()
	if not effect_manager:
		return
	
	# 应用所有宝石效果
	for effect_name in gem_effects:
		var effect_data = {}
		if Data.effects.has(effect_name):
			effect_data = Data.effects.get(effect_name)
		if not effect_data.is_empty():
			effect_manager.apply_effect(target, effect_name, effect_data, self)

func get_effect_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("EffectManager")
	return null

# 设置宝石效果（由发射塔调用）
func setup_gem_effects(tower: Node):
	if not tower or not tower.has_method("get_active_gem_effects"):
		return
	
	gem_effects = tower.get_active_gem_effects()
	equipped_gem = tower.equipped_gem
	element = tower.element
	turret_category = tower.turret_category
	source_tower = tower
