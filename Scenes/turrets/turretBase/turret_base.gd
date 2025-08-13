extends Node2D
class_name Turret

signal turretUpdated
signal gem_equipped(gem_data: Dictionary)
signal gem_unequipped

# 新增属性
var element: String = "neutral"
var equipped_gem: Dictionary = {}
var turret_category: String = ""

# DA/TA System Properties
var da_bonus: float = 0.05  # 5% base DA chance
var ta_bonus: float = 0.01  # 1% base TA chance
var passive_effect: String = ""
var aoe_type: String = "none"
var special_mechanics: Array = []

# Passive bonuses from other towers
var passive_da_bonus: float = 0.0
var passive_ta_bonus: float = 0.0
var passive_damage_bonus: float = 0.0
var passive_speed_bonus: float = 0.0

var turret_type := "":
	set(value):
		turret_type = value
		_setup_turret_data(value)

#Deploying
var deployed := false
var can_place := false
var draw_range := false
#Attacking
var rotates := true
var current_target = null
#Stats
var attack_speed := 1.0:
	set(value):
		attack_speed = value
		var cooldown_node = get_node_or_null("AttackCooldown")
		if cooldown_node:
			cooldown_node.wait_time = 1.0/value
var attack_range := 1.0:
	set(value):
		attack_range = value
		var detection_shape = get_node_or_null("DetectionArea/CollisionShape2D")
		if detection_shape and detection_shape.shape:
			detection_shape.shape.radius = value
var damage := 1.0
var turret_level := 1

func _process(_delta):
	if not deployed:
		_handle_placement_collision()
	elif rotates:
		_handle_target_rotation()

func _draw():
	if draw_range:
		draw_circle(Vector2(0,0), attack_range, "3ccd50a9", false, 1, true)

func set_placeholder():
	modulate = Color("6eff297a")

func build():
	deployed = true
	modulate = Color.WHITE
	# Apply passive bonuses when tower is built
	call_deferred("apply_passive_bonuses")

func colliding():
	can_place = false
	modulate = Color("ff5c2990")

func not_colliding():
	can_place = true
	modulate = Color("6eff297a")

func _on_detection_area_area_entered(area: Area2D) -> void:
	if not deployed or current_target or not is_instance_valid(area):
		return
	
	var area_parent = area.get_parent()
	if not is_instance_valid(area_parent) or not area_parent.is_in_group("enemy"):
		return
	
	# Check stealth logic
	if area_parent.has_method("get_is_stealthed") and area_parent.get_is_stealthed():
		if can_detect_stealth():
			current_target = area_parent
	else:
		current_target = area_parent

func can_detect_stealth() -> bool:
	# 光元素炮塔或装备光宝石的炮塔可以检测隐身
	return element == "light" or (equipped_gem.has("element") and equipped_gem.element == "light")

func _on_detection_area_area_exited(area: Area2D) -> void:
	if not deployed or not is_instance_valid(area):
		return
	
	var area_parent = area.get_parent()
	if is_instance_valid(area_parent) and current_target == area_parent:
		current_target = null
		try_get_closest_target()

## Helper methods for safe node access and game logic
func _setup_turret_data(value: String) -> void:
	if not Data.turrets.has(value):
		push_error("Turret type '" + value + "' not found in Data.turrets")
		return
	
	var turret_data = Data.turrets[value]
	var sprite_node = get_node_or_null("Sprite2D")
	if sprite_node and turret_data.has("sprite"):
		var texture = Data.load_resource_safe(turret_data["sprite"], "Texture2D")
		if texture:
			sprite_node.texture = texture
			var scale_value = turret_data.get("scale", 1.0)
			sprite_node.scale = Vector2(scale_value, scale_value)
	
	rotates = turret_data.get("rotates", false)
	element = turret_data.get("element", "neutral")
	turret_category = turret_data.get("turret_category", "")
	da_bonus = turret_data.get("da_bonus", 0.05)
	ta_bonus = turret_data.get("ta_bonus", 0.01)
	passive_effect = turret_data.get("passive_effect", "")
	aoe_type = turret_data.get("aoe_type", "none")
	special_mechanics = turret_data.get("special_mechanics", [])
	
	if turret_data.has("stats"):
		for stat in turret_data["stats"].keys():
			if has_method("set") and stat in self:
				set(stat, turret_data["stats"][stat])

func _handle_placement_collision() -> void:
	var collision_area = get_node_or_null("CollisionArea")
	if not collision_area:
		return
	
	if collision_area.has_overlapping_areas():
		colliding()
	else:
		not_colliding()

func _handle_target_rotation() -> void:
	if is_instance_valid(current_target):
		look_at(current_target.global_position)
	else:
		try_get_closest_target()

func try_get_closest_target():
	if not deployed:
		return
	
	var detection_area = get_node_or_null("DetectionArea")
	if not detection_area:
		return
	
	var closest = 1000.0
	var closest_area = null
	for area in detection_area.get_overlapping_areas():
		if not is_instance_valid(area):
			continue
		var dist = area.global_position.distance_to(global_position)
		if dist < closest:
			closest = dist
			closest_area = area
	
	if closest_area and is_instance_valid(closest_area):
		var parent = closest_area.get_parent()
		if is_instance_valid(parent):
			current_target = parent

func open_details_pane() -> void:
	if not is_instance_valid(Globals) or not is_instance_valid(Globals.hud):
		push_warning("Cannot open details pane: Globals or HUD not available")
		return
	
	var details_path = Data.get_path("scenes", "ui", "turret_details")
	if details_path == "":
		return
	
	var turret_details_scene = Data.load_resource_safe(details_path, "PackedScene")
	if not turret_details_scene:
		push_error("Failed to load turret details scene")
		return
	
	var details = turret_details_scene.instantiate()
	if not details:
		push_error("Failed to instantiate turret details")
		return
	
	details.turret = self
	draw_range = true
	queue_redraw()
	Globals.hud.add_child(details)
	Globals.hud.open_details_pane = details

func close_details_pane() -> void:
	draw_range = false
	queue_redraw()
	
	if not is_instance_valid(Globals) or not is_instance_valid(Globals.hud):
		return
	
	if is_instance_valid(Globals.hud.open_details_pane):
		Globals.hud.open_details_pane.queue_free()
		Globals.hud.open_details_pane = null

func _on_collision_area_input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if not deployed or not Input.is_action_just_pressed("LeftClick"):
		return
	
	if is_instance_valid(Globals) and is_instance_valid(Globals.hud) and is_instance_valid(Globals.hud.open_details_pane):
		if Globals.hud.open_details_pane.turret == self:
			close_details_pane()
			return
		Globals.hud.open_details_pane.turret.close_details_pane()
	
	open_details_pane()

func upgrade_turret() -> void:
	if not Data.turrets.has(turret_type):
		push_error("Cannot upgrade: turret type '" + turret_type + "' not found")
		return
	
	var turret_data = Data.turrets[turret_type]
	if not turret_data.has("upgrades"):
		push_warning("No upgrades available for turret type: " + turret_type)
		return
	
	turret_level += 1
	var upgrades = turret_data["upgrades"]
	
	for upgrade in upgrades.keys():
		if not upgrade in self:
			continue
		
		var upgrade_data = upgrades[upgrade]
		var current_value = get(upgrade)
		var amount = upgrade_data.get("amount", 1.0)
		var multiplies = upgrade_data.get("multiplies", false)
		
		if multiplies:
			set(upgrade, current_value * amount)
		else:
			set(upgrade, current_value + amount)
	
	turretUpdated.emit()

func attack() -> void:
	if is_instance_valid(current_target):
		# For non-projectile towers, directly call charge system when attacking
		if turret_category != "projectile":
			var charge_system_node = get_charge_system()
			if is_instance_valid(charge_system_node) and has_charge_ability():
				if charge_system_node.has_method("add_charge_on_hit"):
					charge_system_node.add_charge_on_hit(self)
	else:
		try_get_closest_target()

func get_charge_system() -> ChargeSystem:
	var tree = get_tree()
	if not tree or not is_instance_valid(tree.current_scene):
		return null
	
	var charge_node = tree.current_scene.get_node_or_null("ChargeSystem")
	if charge_node and charge_node is ChargeSystem:
		return charge_node as ChargeSystem
	return null

## Calculate number of attacks based on DA/TA probability
## Returns 1 (normal), 2 (DA), or 3 (TA)
func calculate_da_ta_attacks() -> int:
	var total_da = da_bonus + passive_da_bonus
	var total_ta = ta_bonus + passive_ta_bonus
	
	# Clamp values to reasonable bounds from Data configuration
	total_da = clamp(total_da, 0.0, Data.combat_settings.da_max_chance)
	total_ta = clamp(total_ta, 0.0, Data.combat_settings.ta_max_chance)
	
	var rand_val = randf()
	
	# Check TA first (less likely)
	if rand_val < total_ta:
		# Notify PassiveSynergyManager of TA trigger for Doomsday Tower passive
		var synergy_manager = get_passive_synergy_manager()
		if synergy_manager and synergy_manager.has_method("on_ta_triggered"):
			synergy_manager.on_ta_triggered(self)
		return 3
	# Check DA
	elif rand_val < total_da:
		return 2
	# Normal attack
	else:
		return 1

## Apply passive bonuses from PassiveSynergyManager
func apply_passive_bonuses() -> void:
	if not deployed:
		return
		
	# Reset passive bonuses
	passive_da_bonus = 0.0
	passive_ta_bonus = 0.0
	passive_damage_bonus = 0.0
	passive_speed_bonus = 0.0
	
	# Get synergy manager and calculate bonuses
	var synergy_manager = get_passive_synergy_manager()
	if synergy_manager:
		var bonuses = synergy_manager.calculate_tower_bonuses(self)
		passive_da_bonus = bonuses.get("da_bonus") if bonuses.has("da_bonus") else 0.0
		passive_ta_bonus = bonuses.get("ta_bonus") if bonuses.has("ta_bonus") else 0.0
		passive_damage_bonus = bonuses.get("damage_bonus") if bonuses.has("damage_bonus") else 0.0
		passive_speed_bonus = bonuses.get("speed_bonus") if bonuses.has("speed_bonus") else 0.0

## Get effective stats with passive bonuses applied
func get_effective_stats() -> Dictionary:
	return {
		"damage": damage * (1.0 + passive_damage_bonus),
		"attack_speed": attack_speed * (1.0 + passive_speed_bonus),
		"attack_range": attack_range,
		"da_chance": da_bonus + passive_da_bonus,
		"ta_chance": ta_bonus + passive_ta_bonus
	}

func get_passive_synergy_manager():
	var tree = get_tree()
	if tree and tree.current_scene:
		return tree.current_scene.get_node_or_null("PassiveSynergyManager")
	return null

# 新增方法
func equip_gem(gem_data: Dictionary) -> bool:
	# Check if tower can equip this gem level
	var gem_level = gem_data.get("level") if gem_data.has("level") else 1
	if not can_equip_gem_level(gem_level):
		return false
	
	equipped_gem = gem_data
	if gem_data.has("element"):
		element = gem_data.element
	
	# 应用宝石技能
	_apply_gem_skills()
	
	gem_equipped.emit(gem_data)
	turretUpdated.emit()
	return true

func can_equip_gem_level(gem_level: int) -> bool:
	if tower_tech_system:
		return tower_tech_system.can_tower_equip_gem(turret_type, gem_level)
	return gem_level <= 1  # Default: only level 1 gems if no tech system

func get_max_gem_level() -> int:
	if tower_tech_system:
		return tower_tech_system.get_tower_max_gem_level(turret_type)
	return 1

func unequip_gem():
	var old_gem = equipped_gem
	equipped_gem = {}
	element = Data.turrets[turret_type].get("element") if Data.turrets[turret_type].has("element") else "neutral"
	
	# 移除宝石技能效果
	_remove_gem_skills()
	
	gem_unequipped.emit()
	turretUpdated.emit()

func calculate_final_damage(base_damage: float, target_element: String) -> float:
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
	if tree and tree.current_scene:
		var manager = tree.current_scene.get_node_or_null("WeaponWheelManager")
		if manager is WeaponWheelManager:
			return manager as WeaponWheelManager
	return null

func get_element_color() -> Color:
	return ElementSystem.get_element_color(element)

func has_gem_equipped() -> bool:
	return not equipped_gem.is_empty()

func get_total_damage_multiplier(target_element: String) -> float:
	var weapon_manager = get_weapon_wheel_manager()
	if not weapon_manager:
		return 1.0
	
	var turret_multiplier = weapon_manager.calculate_turret_multiplier(turret_category)
	var element_multiplier = weapon_manager.calculate_element_multiplier(element)
	
	if equipped_gem.has("damage_bonus"):
		element_multiplier += equipped_gem.damage_bonus
	
	var effectiveness = ElementSystem.get_effectiveness_multiplier(element, target_element)
	
	return turret_multiplier * element_multiplier * effectiveness

func get_turret_info() -> Dictionary:
	return {
		"type": turret_type,
		"level": turret_level,
		"element": element,
				"category": turret_category,
		"equipped_gem": equipped_gem,
		"damage": damage,
		"attack_speed": attack_speed,
		"attack_range": attack_range
	}

# Charge System Integration
var current_charge: int = 0
var charge_system: ChargeSystem

# Tower Tech System Integration
var tower_tech_system: TowerTechSystem
var tech_specialization: String = "1"

func _ready():
	# Existing _ready code...
	find_charge_system()
	find_tower_tech_system()

func find_charge_system():
	var tree = get_tree()
	if tree and tree.current_scene:
		charge_system = tree.current_scene.get_node_or_null("ChargeSystem")


func get_charge_progress() -> float:
	if not charge_system:
		return 0.0
	return float(charge_system.get_tower_charge(self)) / float(charge_system.max_charge)

func can_use_charge_ability() -> bool:
	return charge_system and charge_system.has_charge_ability(turret_type) and current_charge >= 100

func has_charge_ability() -> bool:
	return charge_system and charge_system.has_charge_ability(turret_type)

func find_tower_tech_system():
	var tree = get_tree()
	if tree and tree.current_scene:
		tower_tech_system = tree.current_scene.get_node_or_null("TowerTechSystem")
		if tower_tech_system:
			tech_specialization = tower_tech_system.get_tower_tech_specialization(turret_type)
			# Apply tech bonuses when tower is ready
			call_deferred("apply_tech_bonuses")

func apply_tech_bonuses():
	if tower_tech_system and deployed:
		tower_tech_system.apply_tech_bonuses_to_tower(self)

# 宝石技能系统
func _apply_gem_skills():
	if equipped_gem.is_empty():
		return
	
	var tower_type_key = _get_tower_type_key()
	if tower_type_key == "":
		return
	
	var tower_skills = equipped_gem.get("tower_skills") if equipped_gem.has("tower_skills") else {}
	var gem_skills = tower_skills.get(tower_type_key) if tower_skills.has(tower_type_key) else {}
	if gem_skills.is_empty():
		return
	
	# 应用技能效果
	for effect_name in gem_skills.effects:
		var effect_data = Data.effects.get(effect_name) if Data.effects.has(effect_name) else {}
		if not effect_data.is_empty():
			_apply_tower_effect(effect_data)

func _remove_gem_skills():
	# 移除所有宝石技能效果
	# 这里需要根据具体实现来清理效果
	pass

func _get_tower_type_key() -> String:
	# 根据塔类型返回对应的key
	match turret_category:
		"projectile":
			return "arrow_tower"
		"melee":
			return "capture_tower"
		"ray":
			return "mage_tower"
		"pulse":
			return "pulse_tower"
		"bounce":
			return "弹射塔"
		"aura":
			return "aura_tower"
		"weakness":
			return "weakness_tower"
		_:
			# 特殊塔类型处理
			if "感应" in turret_type:
				return "感应塔"
			elif "末日" in turret_type:
				return "末日塔"
			else:
				return ""

func _apply_tower_effect(effect_data: Dictionary):
	match effect_data.type:
		"stat_modifier":
			_apply_stat_modifier(effect_data)
		"attack_modifier":
			_apply_attack_modifier(effect_data)
		"damage_modifier":
			_apply_damage_modifier(effect_data)
		"special":
			_apply_special_effect(effect_data)

func _apply_stat_modifier(effect_data: Dictionary):
	var stat = effect_data.get("stat")
	var operation = effect_data.get("operation")
	var value = effect_data.get("value")
	
	if stat == "" or operation == "":
		return
	
	match stat:
		"damage":
			if operation == "multiply":
				damage *= value
			elif operation == "add":
				damage += value
		"attack_speed":
			if operation == "multiply":
				attack_speed *= value
			elif operation == "add":
				attack_speed += value
		"attack_range":
			if operation == "multiply":
				attack_range *= value
			elif operation == "add":
				attack_range += value
		"damage_interval":
			if operation == "add":
				# 伤害间隔修改（用于末日塔）
				if has_method("set_damage_interval"):
					var damage_interval = 1.0
					# Check if damage_interval property exists
					if "damage_interval" in self:
						damage_interval = get("damage_interval")
					call("set_damage_interval", damage_interval + value)
		"movement_speed":
			# 移动速度修改（用于捕获塔的减速效果）
			pass
		"defense":
			# 防御力修改（用于虚弱塔）
			pass
		"charge_speed":
			# 充能速度修改（用于光环塔）
			pass

func _apply_attack_modifier(effect_data: Dictionary):
	var property = effect_data.get("property")
	var value = effect_data.get("value")
	
	if property == "target_count":
		# 多目标攻击（用于箭塔）
		if has_method("set_target_count"):
			call("set_target_count", value)

func _apply_damage_modifier(effect_data: Dictionary):
	var target_element = effect_data.get("target_element")
	var multiplier = effect_data.get("multiplier")
	
	# 元素伤害加成（用于箭塔对风属性敌人）
	if target_element != "" and multiplier != 1.0:
		if has_method("set_element_damage_multiplier"):
			call("set_element_damage_multiplier", target_element, multiplier)

func _apply_special_effect(effect_data: Dictionary):
	var effect_type = effect_data.get("effect_type")
	
	match effect_type:
		"area_burn":
			# 范围灼烧效果（用于捕获塔）
			_setup_area_burn_effect()
		"interrupt":
			# 打断技能引导（用于脉冲塔）
			_setup_interrupt_effect()
		"chance_imprison":
			# 概率禁锢效果（用于脉冲塔）
			_setup_chance_imprison_effect(effect_data)
		"infinite_duration":
			# 无限持续时间（用于末日塔）
			_setup_infinite_duration_effect()
		"knockback":
			# 击退效果（用于脉冲塔）
			_setup_knockback_effect()
		"chance_carbonization":
			# 概率炭化效果（用于脉冲塔）
			_setup_chance_carbonization_effect(effect_data)
		"chain_multiplier":
			# 连锁伤害倍率（用于弹射塔）
			_setup_chain_damage_multiplier()
		"fire_field":
			# 火海效果（用于法师塔）
			_setup_fire_field_effect(effect_data)
		"explosion_on_death":
			# 死亡爆炸效果（用于法师塔）
			_setup_death_explosion_effect()
		"carbonization_field":
			# 炭化领域效果（用于捕获塔）
			_setup_carbonization_field_effect(effect_data)

# 特殊效果设置方法（占位符，具体实现需要根据塔类型）
func _setup_area_burn_effect():
	pass

func _setup_interrupt_effect():
	pass

func _setup_chance_imprison_effect(effect_data: Dictionary):
	pass

func _setup_infinite_duration_effect():
	pass

func _setup_knockback_effect():
	pass

func _setup_chance_carbonization_effect(effect_data: Dictionary):
	pass

func _setup_chain_damage_multiplier():
	pass

func _setup_fire_field_effect(effect_data: Dictionary):
	pass

func _setup_death_explosion_effect():
	pass

func _setup_carbonization_field_effect(effect_data: Dictionary):
	pass

# 获取宝石技能信息
func get_gem_skills_info() -> Array:
	if equipped_gem.is_empty():
		return []
	
	var tower_type_key = _get_tower_type_key()
	if tower_type_key == "":
		return []
	
	var tower_skills = equipped_gem.get("tower_skills") if equipped_gem.has("tower_skills") else {}
	var gem_skills = tower_skills.get(tower_type_key) if tower_skills.has(tower_type_key) else {}
	if gem_skills.is_empty():
		return []
	
	return [gem_skills.name, gem_skills.description]

# 获取当前激活的宝石效果列表
func get_active_gem_effects() -> Array:
	if equipped_gem.is_empty():
		return []
	
	var tower_type_key = _get_tower_type_key()
	if tower_type_key == "":
		return []
	
	var tower_skills = equipped_gem.get("tower_skills") if equipped_gem.has("tower_skills") else {}
	var gem_skills = tower_skills.get(tower_type_key) if tower_skills.has(tower_type_key) else {}
	if gem_skills.is_empty():
		return []
	
	return gem_skills.effects
