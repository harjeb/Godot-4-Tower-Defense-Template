extends Node2D
class_name Turret

# Import required classes
const ChargeSystem = preload("res://Scenes/systems/ChargeSystem.gd")
const WeaponWheelManager = preload("res://Scenes/systems/WeaponWheelManager.gd")
const GemEffectSystem = preload("res://Scenes/systems/GemEffectSystem.gd")
const TowerTechSystem = preload("res://Scenes/systems/TowerTechSystem.gd")

signal turretUpdated
signal gem_equipped(gem_data: Dictionary)
signal gem_unequipped
signal attack_hit(target: Node)
signal projectile_bounce(target: Node)

# 新增属性
var element: String = "neutral"
var equipped_gem: Dictionary = {}
var turret_category: String = ""

# Combat Range Type System
enum CombatType {
	MELEE,    # 近战塔：只能攻击相邻敌人，可以阻挡道路
	RANGED    # 远程塔：远距离攻击，不能阻挡道路
}
var combat_type: CombatType = CombatType.RANGED
var can_block_path: bool = false  # 是否可以阻挡道路
var is_blocking: bool = false     # 当前是否在阻挡状态

# Target Type System
enum TargetType {
	GROUND_ONLY,  # 只能攻击地面单位
	AIR_ONLY,     # 只能攻击飞行单位  
	BOTH          # 可以攻击所有单位
}
var target_type: TargetType = TargetType.BOTH

# Health System for Blocking Towers
var max_health: float = 100.0
var current_health: float = 100.0
var is_alive: bool = true
var respawn_time: float = 5.0
var blocking_collision: StaticBody2D

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
	
	# Add to tower group
	add_to_group("tower")
	
	# Setup blocking collision for melee towers
	if can_block_path:
		setup_blocking_collision()
	
	# Apply passive bonuses when tower is built
	call_deferred("apply_passive_bonuses")

func colliding():
	can_place = false
	modulate = Color("ff5c2990")

func not_colliding():
	can_place = true
	modulate = Color("6eff297a")

func _on_detection_area_area_entered(area: Area2D) -> void:
	if not deployed or current_target or not is_instance_valid(area) or not is_alive:
		return
	
	var area_parent = area.get_parent()
	if not is_instance_valid(area_parent) or not area_parent.is_in_group("enemy"):
		return
	
	# Check if this tower can target this enemy type
	if not can_target_enemy(area_parent):
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
			var scale_value = turret_data.get("scale") if turret_data.has("scale") else 1.0
			sprite_node.scale = Vector2(scale_value, scale_value)
	
	rotates = turret_data.get("rotates") if turret_data.has("rotates") else false
	element = turret_data.get("element") if turret_data.has("element") else "neutral"
	turret_category = turret_data.get("turret_category") if turret_data.has("turret_category") else ""
	
	# Setup combat type and target type
	var combat_type_str = turret_data.get("combat_type") if turret_data.has("combat_type") else "ranged"
	combat_type = CombatType.RANGED if combat_type_str == "ranged" else CombatType.MELEE
	can_block_path = combat_type == CombatType.MELEE
	
	var target_type_str = turret_data.get("target_type") if turret_data.has("target_type") else "both"
	match target_type_str:
		"ground_only":
			target_type = TargetType.GROUND_ONLY
		"air_only":
			target_type = TargetType.AIR_ONLY
		_:
			target_type = TargetType.BOTH
	
	# Health system for blocking towers
	max_health = turret_data.get("max_health", 100.0)
	current_health = max_health
	respawn_time = turret_data.get("respawn_time", 5.0)
	
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
	
	var details_path = Data.get_resource_path("scenes", "ui", "turret_details")
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
	
	# 如果ChargeSystem不存在，显示错误提示（仅显示一次）
	if not has_meta("charge_system_error_shown"):
		set_meta("charge_system_error_shown", true)
		if ErrorHandler and ErrorHandler.has_method("show_error"):
			ErrorHandler.show_error("ChargeSystem 未找到，充能功能将不可用", "系统错误")
	
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
	
	# 冰元素特殊处理：检查目标是否有冰霜减益
	if element == "ice" and current_target and is_instance_valid(current_target):
		var gem_effect_system = get_gem_effect_system()
		if gem_effect_system:
			var frost_stacks = gem_effect_system.get_frost_stacks(current_target)
			if frost_stacks > 0:
				# 冰霜层数增加伤害 (每层2%)
				element_buff_multiplier += frost_stacks * 0.02
	
	# 最终计算：基础伤害 × 炮塔类型BUFF × 元素BUFF × 属性克制
	final_damage = base_damage * turret_buff_multiplier * element_buff_multiplier * effectiveness
	
	# 检查是否有对冻结单位的伤害倍率加成
	if element == "ice" and current_target and is_instance_valid(current_target):
		var gem_effect_system = get_gem_effect_system()
		if gem_effect_system and gem_effect_system.is_target_frozen(current_target):
			# 检查是否有冻结伤害倍率效果
			var active_effects = get_active_gem_effects()
			if "frozen_damage_3x" in active_effects:
				final_damage *= 3.0
	
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
			# 检查具体的炮塔类型
			if "箭塔" in turret_type or "arrow" in turret_type:
				return "arrow_tower"
			elif "捕获" in turret_type or "capture" in turret_type:
				return "capture_tower"
			elif "法师" in turret_type or "mage" in turret_type:
				return "mage_tower"
			elif "弹射" in turret_type or "ricochet" in turret_type or "bounce" in turret_type:
				return "弹射塔"
			elif "虚弱" in turret_type or "weakness" in turret_type:
				return "weakness_tower"
			else:
				return "arrow_tower"  # 默认
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
		"support":
			# 特殊塔类型处理
			if "感应" in turret_type or "detection" in turret_type:
				return "感应塔"
			elif "光环" in turret_type or "aura" in turret_type:
				return "aura_tower"
			else:
				return "感应塔"
		"special":
			if "末日" in turret_type or "doomsday" in turret_type:
				return "末日塔"
			elif "脉冲" in turret_type or "pulse" in turret_type:
				return "pulse_tower"
			else:
				return "末日塔"
		_:
			# 特殊塔类型处理
			if "感应" in turret_type or "detection" in turret_type:
				return "感应塔"
			elif "末日" in turret_type or "doomsday" in turret_type:
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
		# 冰元素特殊效果
		"frost_area":
			# 冰霜区域效果（用于脉冲塔）
			_setup_frost_area_effect(effect_data)
		"frost_on_bounce":
			# 弹射冰霜效果（用于弹射塔）
			_setup_frost_bounce_effect(effect_data)
		"aura_slow":
			# 冰霜光环效果（用于光环塔）
			_setup_frost_aura_effect(effect_data)
		"chance_freeze":
			# 概率冻结效果
			_setup_chance_freeze_effect(effect_data)
		"chance_freeze_bounce":
			# 弹射概率冻结效果
			_setup_chance_freeze_bounce_effect(effect_data)
		"freeze_main_target":
			# 主目标冻结效果（用于法师塔）
			_setup_freeze_main_target_effect(effect_data)
		"freeze_on_effect_end":
			# 效果结束时冻结（用于捕获塔、末日塔）
			_setup_freeze_on_end_effect(effect_data)
		"freeze_stealth_units":
			# 冻结隐身单位（用于感应塔）
			_setup_freeze_stealth_effect(effect_data)
		"freeze_on_death":
			# 死亡时冻结（用于末日塔）
			_setup_freeze_on_death_effect()
		"frost_ground":
			# 冰霜地面效果（用于脉冲塔）
			_setup_frost_ground_effect(effect_data)
		"frozen_damage_multiplier":
			# 对冻结单位伤害倍率（用于脉冲塔）
			_setup_frozen_damage_multiplier_effect(effect_data)
		"freeze_duration_bonus":
			# 冻结时间加成（用于光环塔）
			_setup_freeze_duration_bonus_effect(effect_data)
		"periodic_frost":
			# 周期性冰霜效果（用于光环塔）
			_setup_periodic_frost_effect(effect_data)
		"priority_targeting":
			# 优先目标效果（用于感应塔）
			_setup_priority_target_effect()
		"stealth_slow":
			# 隐身单位减速（用于感应塔）
			_setup_stealth_slow_effect(effect_data)
		"capture_slow_bonus":
			# 捕获减速加成（用于捕获塔）
			_setup_capture_slow_bonus_effect(effect_data)
		"frost_debuff_area":
			# 区域冰霜减益（用于法师塔）
			_setup_frost_debuff_area_effect(effect_data)
		# 土元素特殊效果
		"weight_area":
			# 重压区域效果（用于脉冲塔）
			_setup_weight_area_effect(effect_data)
		"armor_break_on_bounce":
			# 破甲弹射效果（用于弹射塔）
			_setup_armor_break_on_bounce_effect(effect_data)
		"meteor":
			# 陨石攻击效果（用于法师塔）
			_setup_meteor_attack_effect(effect_data)
		"triple_meteor":
			# 三重陨石效果（用于法师塔）
			_setup_triple_meteor_effect(effect_data)
		"aoe":
			# 范围攻击效果（用于箭塔）
			_setup_aoe_attack_effect(effect_data)
		"thorns":
			# 反伤效果（用于光环塔）
			_setup_thorns_effect(effect_data)
		"chance_petrify":
			# 概率石化效果
			_setup_chance_petrify_effect(effect_data)
		"continuous_defense_reduction":
			# 持续防御力降低效果（用于末日塔）
			_setup_continuous_defense_reduction_effect(effect_data)
		"max_hp_damage":
			# 最大生命值百分比伤害效果（用于末日塔）
			_setup_max_hp_damage_effect(effect_data)
		"aftershock":
			# 余震效果（用于脉冲塔）
			_setup_aftershock_effect(effect_data)
		"tower_shield":
			# 护盾效果（用于脉冲塔）
			_setup_tower_shield_effect(effect_data)
		"weight_area_all_ground":
			# 所有地面单位重压效果（用于感应塔）
			_setup_weight_all_ground_effect(effect_data)
		"infinite_duration":
			# 无限持续时间（用于末日塔）
			_setup_infinite_duration_effect()
		"petrify_obelisk_on_death":
			# 死亡时石化方尖塔效果（用于末日塔）
			_setup_petrify_obelisk_on_death_effect()
		"petrify_chance_bounce":
			# 弹射概率石化效果（用于弹射塔）
			_setup_petrify_chance_bounce_effect(effect_data)
		"refresh_on_petrify":
			# 石化时刷新效果（用于弹射塔）
			_setup_refresh_on_petrify_effect()
		"extra_targets":
			# 额外目标效果（用于弹射塔）
			_setup_extra_targets_effect(effect_data)
		"immune_armor_break":
			# 免疫破甲效果（用于光环塔）
			_setup_immune_armor_break_effect()
		"permanent_weight_field":
			# 永久重压领域效果（用于捕获塔）
			_setup_permanent_weight_field_effect(effect_data)
		"petrify_on_move":
			# 移动时石化效果（用于感应塔）
			_setup_petrify_on_move_effect(effect_data)
		# 风元素效果
		"attack_speed_boost":
			# 攻击速度提升效果
			_setup_attack_speed_boost_effect(effect_data)
		"knockback":
			# 击退效果
			_setup_knockback_target_effect(effect_data)
		"knockback_all":
			# 范围击退效果
			_setup_knockback_all_effect(effect_data)
		"imbalance_area":
			# 失衡区域效果
			_setup_imbalance_area_effect(effect_data)
		"imbalance_stealth":
			# 失衡隐身单位效果
			_setup_imbalance_stealth_effect(effect_data)
		"silence":
			# 沉默效果
			_setup_silence_target_effect(effect_data)
		"silence_stealth":
			# 沉默隐身单位效果
			_setup_silence_stealth_effect(effect_data)
		"silence_chance":
			# 概率沉默效果
			_setup_silence_chance_effect(effect_data)
		"multi_wind_blades":
			# 多重风刃效果
			_setup_multi_wind_blades_effect(effect_data)
		"capture_range":
			# 捕获范围提升效果
			_setup_capture_range_effect(effect_data)
		"pull_to_center":
			# 拉向中心效果
			_setup_pull_to_center_effect(effect_data)
		"wind_blades_bounce":
			# 风刃弹射效果
			_setup_wind_blades_bounce_effect(effect_data)
		"reveal_nearby":
			# 显现周围敌人效果
			_setup_reveal_nearby_effect(effect_data)
		"dodge_chance":
			# 闪避几率效果
			_setup_dodge_chance_effect(effect_data)
		"ricochet_count":
			# 弹射次数效果
			_setup_ricochet_count_effect(effect_data)
		"attack_speed_aura":
			# 攻击速度光环效果
			_setup_attack_speed_aura_effect(effect_data)
		"fast_ricochet":
			# 快速弹射效果
			_setup_fast_ricochet_effect(effect_data)
		"piercing":
			# 穿透攻击效果
			_setup_piercing_attack_effect(effect_data)
		"chain_targets":
			# 多目标攻击效果
			_setup_multi_target_effect(effect_data)
		"tornado":
			# 龙卷风效果
			_setup_tornado_effect(effect_data)
		"imprison":
			# 禁锢敌人效果
			_setup_imprison_enemies_effect(effect_data)
		"knockback_on_end":
			# 结束时击退效果
			_setup_knockback_on_end_effect(effect_data)
		"hurricane":
			# 飓风效果
			_setup_hurricane_effect(effect_data)
		"flying_debuff":
			# 飞行单位减益效果
			_setup_flying_debuff_effect(effect_data)
		"exile":
			# 放逐效果
			_setup_exile_effect(effect_data)
		"damage_on_return":
			# 回归时伤害效果
			_setup_damage_on_return_effect(effect_data)
		"ally_attack_speed":
			# 友方攻击速度效果
			_setup_ally_attack_speed_effect(effect_data)
		"bonus_damage_on_end":
			# 结束时额外伤害效果
			_setup_bonus_damage_on_end_effect(effect_data)
		# 光元素特殊效果
		"blind":
			# 致盲效果
			_setup_blind_effect(effect_data)
		"purify":
			# 净化效果
			_setup_purify_effect(effect_data)
		"judgment":
			# 审判效果
			_setup_judgment_effect(effect_data)
		"holy_damage":
			# 神圣伤害效果
			_setup_holy_damage_effect(effect_data)
		"heal_towers":
			# 治疗友方塔效果
			_setup_heal_towers_effect(effect_data)
		"energy_return":
			# 能量返还效果
			_setup_energy_return_effect(effect_data)
		"anti_stealth":
			# 反隐身效果
			_setup_anti_stealth_effect(effect_data)
		"judgment_spread":
			# 审判扩散效果
			_setup_judgment_spread_effect(effect_data)
		# 暗元素特殊效果
		"corrosion":
			# 腐蚀效果
			_setup_corrosion_effect(effect_data)
		"life_steal":
			# 生命偷取效果
			_setup_life_steal_effect(effect_data)
		"healing_reduction":
			# 治疗效果降低
			_setup_healing_reduction_effect(effect_data)
		"death_contagion":
			# 死亡传染效果
			_setup_death_contagion_effect(effect_data)
		"chance_fear":
			# 概率恐惧效果
			_setup_chance_fear_effect(effect_data)
		"fear_area":
			# 恐惧区域效果
			_setup_fear_area_effect(effect_data)
		"no_healing":
			# 无法治疗效果
			_setup_no_healing_effect(effect_data)
		"channel_life_drain":
			# 引导生命虹吸效果
			_setup_channel_life_drain_effect(effect_data)
		"fear_area_detection":
			# 恐惧侦测效果
			_setup_fear_area_detection_effect(effect_data)
		"global_life_steal":
			# 全局生命偷取效果
			_setup_global_life_steal_effect(effect_data)
		"corrosion_aura":
			# 腐蚀光环效果
			_setup_corrosion_aura_effect(effect_data)
		"life_drain_aura":
			# 生命虹吸光环效果
			_setup_life_drain_aura_effect(effect_data)
		"permanent_stat_steal":
			# 永久属性偷取效果
			_setup_permanent_stat_steal_effect(effect_data)
		"area_life_steal":
			# 范围生命偷取效果
			_setup_area_life_steal_effect(effect_data)
		"life_cost":
			# 生命消耗效果
			_setup_life_cost_effect(effect_data)
		"damage_multiplier":
			# 伤害倍率效果
			_setup_damage_multiplier_effect(effect_data)
		"fear_on_hit":
			# 攻击恐惧效果
			_setup_fear_on_hit_effect(effect_data)
		"stealth_life_drain":
			# 隐身生命虹吸效果
			_setup_stealth_life_drain_effect(effect_data)
		"stat_steal_on_death":
			# 死亡属性偷取效果
			_setup_stat_steal_on_death_effect(effect_data)
		"targeting_priority":
			# 目标优先级效果
			_setup_targeting_priority_effect(effect_data)

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

# 冰元素效果实现方法
func _setup_frost_area_effect(effect_data: Dictionary):
	# 脉冲塔冰霜脉冲效果
	var stacks = effect_data.get("stacks", 1)
	var radius = effect_data.get("radius", 85.0)
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		# 连接攻击信号以应用冰霜区域效果
		if not attack_hit.is_connected(_on_frost_area_attack):
			attack_hit.connect(_on_frost_area_attack.bind(stacks, radius))

func _on_frost_area_attack(target: Node, stacks: int, radius: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_frost_area_effect(global_position, radius, stacks)

func _setup_frost_bounce_effect(effect_data: Dictionary):
	# 弹射塔冰片弹射效果
	var stacks = effect_data.get("stacks", 1)
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		# 连接弹射信号以应用冰霜效果
		if not projectile_bounce.is_connected(_on_frost_bounce):
			projectile_bounce.connect(_on_frost_bounce.bind(stacks))

func _on_frost_bounce(target: Node, stacks: int):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system and target.has_method("set_frost_stacks"):
		target.set_frost_stacks(stacks)

func _setup_frost_aura_effect(effect_data: Dictionary):
	# 光环塔寒冰光环效果
	var slow_amount = effect_data.get("slow_amount", 0.05)
	var radius = effect_data.get("radius", 150.0)
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		# 启动光环定时器
		_start_frost_aura_timer(slow_amount, radius)

func _start_frost_aura_timer(slow_amount: float, radius: float):
	var timer = Timer.new()
	timer.name = "FrostAuraTimer"
	timer.wait_time = 1.0  # 每秒应用一次
	timer.autostart = true
	timer.timeout.connect(_on_frost_aura_tick.bind(slow_amount, radius))
	add_child(timer)

func _on_frost_aura_tick(slow_amount: float, radius: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_frost_aura_effect(global_position, radius, slow_amount)

func _setup_chance_freeze_effect(effect_data: Dictionary):
	# 概率冻结效果
	var chance = effect_data.get("chance", 0.15)
	var duration = effect_data.get("duration", 1.0)
	# 在攻击时应用概率冻结
	pass

func _setup_chance_freeze_bounce_effect(effect_data: Dictionary):
	# 弹射概率冻结效果
	var chance = effect_data.get("chance", 0.20)
	var duration = effect_data.get("duration", 0.5)
	# 在弹射时应用概率冻结
	pass

func _setup_freeze_main_target_effect(effect_data: Dictionary):
	# 法师塔冰川尖刺主目标冻结
	var duration = effect_data.get("duration", 2.0)
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		# 连接攻击信号以冻结主目标
		if not attack_hit.is_connected(_on_freeze_main_target):
			attack_hit.connect(_on_freeze_main_target.bind(duration))

func _on_freeze_main_target(target: Node, duration: float):
	if target.has_method("set_frozen"):
		target.set_frozen(true, duration)

func _setup_freeze_on_end_effect(effect_data: Dictionary):
	# 捕获塔、末日塔效果结束时冻结
	var duration = effect_data.get("duration", 1.5)
	# 在效果结束时应用冻结
	pass

func _setup_freeze_stealth_effect(effect_data: Dictionary):
	# 感应塔冻结隐身单位
	var duration = effect_data.get("duration", 1.0)
	# 对隐身单位应用冻结
	pass

func _setup_freeze_on_death_effect():
	# 末日塔死亡时冻结周围敌人
	# 在单位死亡时触发范围冻结
	pass

func _setup_frost_ground_effect(effect_data: Dictionary):
	# 脉冲塔极寒风暴冰霜地面
	var duration = effect_data.get("duration", 3.0)
	# 创建冰霜地面区域效果
	pass

func _setup_frozen_damage_multiplier_effect(effect_data: Dictionary):
	# 对冻结单位伤害倍率
	var multiplier = effect_data.get("multiplier", 3.0)
	# 设置对冻结单位的伤害倍率
	pass

func _setup_freeze_duration_bonus_effect(effect_data: Dictionary):
	# 冻结时间加成
	var bonus = effect_data.get("bonus", 0.20)
	# 增加冻结效果持续时间
	pass

func _setup_periodic_frost_effect(effect_data: Dictionary):
	# 周期性冰霜效果
	var interval = effect_data.get("interval", 2.0)
	# 定期应用冰霜效果
	pass

func _setup_priority_target_effect():
	# 感应塔优先目标效果
	# 标记目标为优先攻击目标
	pass

func _setup_stealth_slow_effect(effect_data: Dictionary):
	# 感应塔隐身单位减速
	var slow_amount = effect_data.get("slow_amount", 0.20)
	# 对隐身单位应用额外减速
	pass

func _setup_capture_slow_bonus_effect(effect_data: Dictionary):
	# 捕获塔减速加成
	var slow_multiplier = effect_data.get("slow_multiplier", 1.0)
	var duration_bonus = effect_data.get("duration_bonus", 0.5)
	# 增强捕获减速效果
	pass

func _setup_frost_debuff_area_effect(effect_data: Dictionary):
	# 法师塔区域冰霜减益
	var stacks = effect_data.get("stacks", 2)
	# 在攻击范围内应用冰霜减益
	pass

# 土元素效果实现方法
func _setup_weight_area_effect(effect_data: Dictionary):
	# 脉冲塔地震波重压区域效果
	var stacks = effect_data.get("stacks", 1)
	var radius = effect_data.get("radius", 85.0)
	# 连接攻击信号以应用重压区域效果
	if not attack_hit.is_connected(_on_weight_area_attack):
		attack_hit.connect(_on_weight_area_attack.bind(stacks, radius))

func _on_weight_area_attack(target: Node, stacks: int, radius: float):
	apply_weight_area_effect(global_position, radius, stacks)

func _setup_armor_break_on_bounce_effect(effect_data: Dictionary):
	# 弹射塔碎石弹破甲效果
	var stacks = effect_data.get("stacks", 1)
	# 连接弹射信号以应用破甲效果
	if not projectile_bounce.is_connected(_on_armor_break_bounce):
		projectile_bounce.connect(_on_armor_break_bounce.bind(stacks))

func _on_armor_break_bounce(target: Node, stacks: int):
	apply_armor_break_on_bounce_effect(target, stacks)

func _setup_meteor_attack_effect(effect_data: Dictionary):
	# 法师塔陨石术效果
	# 修改攻击为范围陨石攻击
	var damage_boost = effect_data.get("damage_boost", 0.30)
	damage *= (1.0 + damage_boost)
	# 设置AOE范围
	aoe_type = "circle"

func _setup_triple_meteor_effect(effect_data: Dictionary):
	# 法师塔泰坦之怒三重陨石效果
	# 连续发射3颗陨石
	var damage_boost = effect_data.get("damage_boost", 0.50)
	damage *= (1.0 + damage_boost)
	# 设置多重攻击
	if has_method("set_multi_shot"):
		call("set_multi_shot", 3)

func _setup_aoe_attack_effect(effect_data: Dictionary):
	# 箭塔地龙击范围攻击效果
	# 修改攻击为范围攻击
	aoe_type = "circle"

func _setup_thorns_effect(effect_data: Dictionary):
	# 光环塔反伤效果
	var percentage = effect_data.get("percentage", 0.05)
	# 设置反伤百分比
	if has_method("set_thorns_percentage"):
		call("set_thorns_percentage", percentage)

func _setup_chance_petrify_effect(effect_data: Dictionary):
	# 概率石化效果
	var chance = effect_data.get("chance", 0.20)
	var duration = effect_data.get("duration", 1.0)
	# 在攻击时应用概率石化
	if not attack_hit.is_connected(_on_chance_petrify_attack):
		attack_hit.connect(_on_chance_petrify_attack.bind(chance, duration))

func _on_chance_petrify_attack(target: Node, chance: float, duration: float):
	apply_chance_petrify_effect(target, chance, duration)

func _setup_continuous_defense_reduction_effect(effect_data: Dictionary):
	# 末日塔石化凝视持续防御力降低效果
	var max_reduction = effect_data.get("max_reduction", 0.30)
	# 设置持续防御力降低
	if has_method("set_continuous_defense_reduction"):
		call("set_continuous_defense_reduction", max_reduction)

func _setup_max_hp_damage_effect(effect_data: Dictionary):
	# 末日塔地心熔毁最大生命值百分比伤害效果
	var percentage = effect_data.get("percentage", 0.01)
	# 设置最大生命值百分比伤害
	if not attack_hit.is_connected(_on_max_hp_damage_attack):
		attack_hit.connect(_on_max_hp_damage_attack.bind(percentage))

func _on_max_hp_damage_attack(target: Node, percentage: float):
	apply_max_hp_damage_effect(target, percentage)

func _setup_aftershock_effect(effect_data: Dictionary):
	# 脉冲塔余震效果
	var chance = effect_data.get("chance", 0.25)
	var damage_multiplier = effect_data.get("damage_multiplier", 0.5)
	# 设置余震几率和伤害倍率
	if not attack_hit.is_connected(_on_aftershock_attack):
		attack_hit.connect(_on_aftershock_attack.bind(chance, damage_multiplier))

func _on_aftershock_attack(target: Node, chance: float, damage_multiplier: float):
	if randf() < chance:
		apply_aftershock_effect(global_position, 50.0, damage_multiplier)

func _setup_tower_shield_effect(effect_data: Dictionary):
	# 脉冲塔大地脉动护盾效果
	var shield_amount = effect_data.get("shield_amount", 100.0)
	# 为友方塔提供护盾
	_apply_tower_shield_to_allies(shield_amount)

func _apply_tower_shield_to_allies(shield_amount: float):
	# 为范围内的友方塔提供护盾
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var radius = 100.0  # 护盾范围
	var towers = tree.current_scene.get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if is_instance_valid(tower) and tower != self:
			var distance = tower.global_position.distance_to(global_position)
			if distance <= radius:
				apply_tower_shield_effect(tower, shield_amount)

func _setup_weight_all_ground_effect(effect_data: Dictionary):
	# 感应塔地脉感应所有地面单位重压效果
	var stacks = effect_data.get("stacks", 1)
	# 启动定时器定期应用重压效果
	_start_weight_all_ground_timer(stacks)

func _start_weight_all_ground_timer(stacks: int):
	var timer = Timer.new()
	timer.name = "WeightAllGroundTimer"
	timer.wait_time = 2.0  # 每2秒应用一次
	timer.autostart = true
	timer.timeout.connect(_on_weight_all_ground_tick.bind(stacks))
	add_child(timer)

func _on_weight_all_ground_tick(stacks: int):
	apply_weight_all_ground_effect(stacks)

func _setup_petrify_obelisk_on_death_effect():
	# 末日塔世界崩塌死亡时石化方尖塔效果
	# 在单位死亡时触发石化方尖塔
	pass

func _setup_petrify_chance_bounce_effect(effect_data: Dictionary):
	# 弹射塔山崩弹射概率石化效果
	var chance = effect_data.get("chance", 0.30)
	var duration = effect_data.get("duration", 1.0)
	# 在弹射时应用概率石化
	if not projectile_bounce.is_connected(_on_petrify_chance_bounce):
		projectile_bounce.connect(_on_petrify_chance_bounce.bind(chance, duration))

func _on_petrify_chance_bounce(target: Node, chance: float, duration: float):
	if randf() < chance:
		apply_chance_petrify_effect(target, 1.0, duration)
		# 石化时刷新弹射次数
		if has_method("refresh_bounce_count"):
			call("refresh_bounce_count")

func _setup_refresh_on_petrify_effect():
	# 弹射塔石化时刷新效果
	# 当目标被石化时刷新弹射
	pass

func _setup_extra_targets_effect(effect_data: Dictionary):
	# 弹射塔山崩额外目标效果
	var extra_targets = effect_data.get("value", 2)
	# 增加弹射目标数量
	if has_method("set_extra_targets"):
		call("set_extra_targets", extra_targets)

func _setup_immune_armor_break_effect():
	# 光环塔泰坦光环免疫破甲效果
	# 设置免疫破甲
	if has_method("set_immune_armor_break"):
		call("set_immune_armor_break", true)

func _setup_permanent_weight_field_effect(effect_data: Dictionary):
	# 捕获塔地覆天翻永久重压领域效果
	# 创建永久重压领域
	_create_permanent_weight_field()

func _create_permanent_weight_field():
	# 创建永久重压领域区域
	# 实际实现需要创建持续的区域效果
	apply_permanent_weight_field_effect(global_position, 100.0)

func _setup_petrify_on_move_effect(effect_data: Dictionary):
	# 感应塔震感移动时石化效果
	var chance = effect_data.get("chance", 0.20)
	var duration = effect_data.get("duration", 0.5)
	# 当隐身单位移动时应用石化
	pass

# 风元素特殊效果设置方法
func _setup_attack_speed_boost_effect(effect_data: Dictionary):
	# 攻击速度提升效果
	var bonus = effect_data.get("bonus", 0.15)
	damage *= (1.0 + bonus)

func _setup_knockback_target_effect(effect_data: Dictionary):
	# 击退目标效果
	var force = effect_data.get("force", 150.0)
	# 连接攻击信号以应用击退
	if not attack_hit.is_connected(_on_knockback_attack):
		attack_hit.connect(_on_knockback_attack.bind(force))

func _setup_knockback_all_effect(effect_data: Dictionary):
	# 范围击退效果
	var force = effect_data.get("force", 200.0)
	# 连接攻击信号以应用范围击退
	if not attack_hit.is_connected(_on_knockback_all_attack):
		attack_hit.connect(_on_knockback_all_attack.bind(force))

func _setup_imbalance_area_effect(effect_data: Dictionary):
	# 失衡区域效果
	var duration = effect_data.get("duration", 2.0)
	# 连接攻击信号以应用失衡区域
	if not attack_hit.is_connected(_on_imbalance_area_attack):
		attack_hit.connect(_on_imbalance_area_attack.bind(duration))

func _setup_imbalance_stealth_effect(effect_data: Dictionary):
	# 失衡隐身单位效果
	var duration = effect_data.get("duration", 2.0)
	# 连接攻击信号以应用失衡到隐身单位
	if not attack_hit.is_connected(_on_imbalance_stealth_attack):
		attack_hit.connect(_on_imbalance_stealth_attack.bind(duration))

func _setup_silence_target_effect(effect_data: Dictionary):
	# 沉默目标效果
	var duration = effect_data.get("duration", 3.0)
	# 连接攻击信号以应用沉默
	if not attack_hit.is_connected(_on_silence_attack):
		attack_hit.connect(_on_silence_attack.bind(duration))

func _setup_silence_stealth_effect(effect_data: Dictionary):
	# 沉默隐身单位效果
	var duration = effect_data.get("duration", 3.0)
	# 连接攻击信号以应用沉默到隐身单位
	if not attack_hit.is_connected(_on_silence_stealth_attack):
		attack_hit.connect(_on_silence_stealth_attack.bind(duration))

func _setup_silence_chance_effect(effect_data: Dictionary):
	# 概率沉默效果
	var chance = effect_data.get("chance", 0.15)
	var duration = effect_data.get("duration", 2.0)
	# 连接攻击信号以应用概率沉默
	if not attack_hit.is_connected(_on_silence_chance_attack):
		attack_hit.connect(_on_silence_chance_attack.bind(chance, duration))

func _setup_multi_wind_blades_effect(effect_data: Dictionary):
	# 多重风刃效果
	var blade_count = effect_data.get("blade_count", 3)
	# 设置多重射击
	if has_method("set_multi_shot"):
		call("set_multi_shot", blade_count)

func _setup_capture_range_effect(effect_data: Dictionary):
	# 捕获范围提升效果
	var range_multiplier = effect_data.get("range_multiplier", 1.30)
	attack_range *= range_multiplier

func _setup_pull_to_center_effect(effect_data: Dictionary):
	# 拉向中心效果
	var force = effect_data.get("force", 100.0)
	# 连接攻击信号以应用拉力效果
	if not attack_hit.is_connected(_on_pull_to_center_attack):
		attack_hit.connect(_on_pull_to_center_attack.bind(force))

func _setup_wind_blades_bounce_effect(effect_data: Dictionary):
	# 风刃弹射效果
	var bounce_count = effect_data.get("bounce_count", 1)
	# 设置弹射次数
	if has_method("set_bounce_count"):
		call("set_bounce_count", bounce_count)

func _setup_reveal_nearby_effect(effect_data: Dictionary):
	# 显现周围敌人效果
	var reveal_range = effect_data.get("range", 100.0)
	# 连接攻击信号以应用显现效果
	if not attack_hit.is_connected(_on_reveal_nearby_attack):
		attack_hit.connect(_on_reveal_nearby_attack.bind(reveal_range))

func _setup_dodge_chance_effect(effect_data: Dictionary):
	# 闪避几率效果
	var dodge_chance = effect_data.get("chance", 0.50)
	# 为自身添加闪避效果
	if has_method("set_dodge_chance"):
		call("set_dodge_chance", dodge_chance)

func _setup_ricochet_count_effect(effect_data: Dictionary):
	# 弹射次数效果
	var count = effect_data.get("value", 2)
	# 设置弹射次数
	if has_method("set_bounce_count"):
		call("set_bounce_count", count)

func _setup_attack_speed_aura_effect(effect_data: Dictionary):
	# 攻击速度光环效果
	var bonus = effect_data.get("bonus", 0.05)
	var aura_range = effect_data.get("range", 150.0)
	# 启动光环定时器
	_start_attack_speed_aura_timer(bonus, aura_range)

func _setup_fast_ricochet_effect(effect_data: Dictionary):
	# 快速弹射效果
	var speed_multiplier = effect_data.get("speed_multiplier", 2.0)
	# 设置投射物速度
	if has_method("set_projectile_speed"):
		call("set_projectile_speed", speed_multiplier)

func _setup_piercing_attack_effect(effect_data: Dictionary):
	# 穿透攻击效果
	# 设置穿透属性
	if has_method("set_piercing"):
		call("set_piercing", true)

func _setup_multi_target_effect(effect_data: Dictionary):
	# 多目标攻击效果
	var target_count = effect_data.get("value", 2)
	var damage_multiplier = effect_data.get("damage_multiplier", 0.5)
	# 设置链式目标
	if has_method("set_chain_targets"):
		call("set_chain_targets", target_count, damage_multiplier)

func _setup_tornado_effect(effect_data: Dictionary):
	# 龙卷风效果
	var duration = effect_data.get("duration", 4.0)
	# 连接攻击信号以应用龙卷风
	if not attack_hit.is_connected(_on_tornado_attack):
		attack_hit.connect(_on_tornado_attack.bind(duration))

func _setup_imprison_enemies_effect(effect_data: Dictionary):
	# 禁锢敌人效果
	var duration = effect_data.get("duration", 4.0)
	# 连接攻击信号以应用禁锢
	if not attack_hit.is_connected(_on_imprison_attack):
		attack_hit.connect(_on_imprison_attack.bind(duration))

func _setup_knockback_on_end_effect(effect_data: Dictionary):
	# 结束时击退效果
	var force = effect_data.get("force", 200.0)
	# 连接攻击信号以应用结束时击退
	if not attack_hit.is_connected(_on_knockback_on_end_attack):
		attack_hit.connect(_on_knockback_on_end_attack.bind(force))

func _setup_hurricane_effect(effect_data: Dictionary):
	# 飓风效果
	var duration = effect_data.get("duration", 5.0)
	var pull_force = effect_data.get("pull_force", 50.0)
	var damage_per_second = effect_data.get("damage_per_second", 20.0)
	# 连接攻击信号以应用飓风
	if not attack_hit.is_connected(_on_hurricane_attack):
		attack_hit.connect(_on_hurricane_attack.bind(duration, pull_force, damage_per_second))

func _setup_flying_debuff_effect(effect_data: Dictionary):
	# 飞行单位减益效果
	var speed_reduction = effect_data.get("speed_reduction", 0.20)
	var attack_speed_reduction = effect_data.get("attack_speed_reduction", 0.20)
	# 连接攻击信号以应用飞行减益
	if not attack_hit.is_connected(_on_flying_debuff_attack):
		attack_hit.connect(_on_flying_debuff_attack.bind(speed_reduction, attack_speed_reduction))

func _setup_exile_effect(effect_data: Dictionary):
	# 放逐效果
	var duration = effect_data.get("duration", 8.0)
	# 连接攻击信号以应用放逐
	if not attack_hit.is_connected(_on_exile_attack):
		attack_hit.connect(_on_exile_attack.bind(duration))

func _setup_damage_on_return_effect(effect_data: Dictionary):
	# 回归时伤害效果
	var damage_multiplier = effect_data.get("damage_multiplier", 1.0)
	# 设置回归伤害倍率
	if has_method("set_damage_on_return_multiplier"):
		call("set_damage_on_return_multiplier", damage_multiplier)

func _setup_ally_attack_speed_effect(effect_data: Dictionary):
	# 友方攻击速度效果
	var bonus = effect_data.get("bonus", 0.30)
	var aura_range = effect_data.get("range", 200.0)
	# 启动友方光环定时器
	_start_ally_attack_speed_timer(bonus, aura_range)

func _setup_bonus_damage_on_end_effect(effect_data: Dictionary):
	# 结束时额外伤害效果
	var damage_multiplier = effect_data.get("damage_multiplier", 0.20)
	# 设置额外伤害倍率
	if has_method("set_bonus_damage_on_end_multiplier"):
		call("set_bonus_damage_on_end_multiplier", damage_multiplier)

# 光元素效果设置方法
func _setup_blind_effect(effect_data: Dictionary):
	# 致盲效果
	var duration = effect_data.get("duration", 1.5)
	var miss_chance = effect_data.get("miss_chance", 0.50)
	# 连接攻击信号以应用致盲
	if not attack_hit.is_connected(_on_blind_attack):
		attack_hit.connect(_on_blind_attack.bind(duration, miss_chance))

func _setup_purify_effect(effect_data: Dictionary):
	# 净化效果
	var duration = effect_data.get("duration", 0.0)
	var heal_amount = effect_data.get("heal_amount", 0.0)
	var energy_return = effect_data.get("energy_return", 0.0)
	# 连接攻击信号以应用净化
	if not attack_hit.is_connected(_on_purify_attack):
		attack_hit.connect(_on_purify_attack.bind(duration, heal_amount, energy_return))

func _setup_judgment_effect(effect_data: Dictionary):
	# 审判效果
	var duration = effect_data.get("duration", 5.0)
	var damage_multiplier = effect_data.get("damage_multiplier", 1.20)
	# 连接攻击信号以应用审判
	if not attack_hit.is_connected(_on_judgment_attack):
		attack_hit.connect(_on_judgment_attack.bind(duration, damage_multiplier))

func _setup_holy_damage_effect(effect_data: Dictionary):
	# 神圣伤害效果
	var multiplier = effect_data.get("multiplier", 1.0)
	# 设置神圣伤害倍率
	if has_method("set_holy_damage_multiplier"):
		call("set_holy_damage_multiplier", multiplier)

func _setup_heal_towers_effect(effect_data: Dictionary):
	# 治疗友方塔效果
	var heal_amount = effect_data.get("heal_amount", 25.0)
	var radius = effect_data.get("radius", 100.0)
	# 启动治疗定时器
	_start_heal_towers_timer(heal_amount, radius)

func _setup_energy_return_effect(effect_data: Dictionary):
	# 能量返还效果
	var energy_amount = effect_data.get("energy_amount", 5.0)
	# 设置能量返还
	if has_method("set_energy_return_amount"):
		call("set_energy_return_amount", energy_amount)

func _setup_anti_stealth_effect(effect_data: Dictionary):
	# 反隐身效果
	var effectiveness = effect_data.get("effectiveness", 2.0)
	# 增强对隐身单位的检测效果
	if has_method("set_anti_stealth_effectiveness"):
		call("set_anti_stealth_effectiveness", effectiveness)

func _setup_judgment_spread_effect(effect_data: Dictionary):
	# 审判扩散效果
	var radius = effect_data.get("radius", 50.0)
	var damage = effect_data.get("damage", 30.0)
	# 设置审判扩散参数
	if has_method("set_judgment_spread_params"):
		call("set_judgment_spread_params", radius, damage)

# 风元素事件处理方法
func _on_knockback_attack(target: Node, force: float):
	apply_knockback_effect(target, force)

func _on_knockback_all_attack(target: Node, force: float):
	apply_knockback_all_effect(global_position, 85.0, force)

func _on_imbalance_area_attack(target: Node, duration: float):
	apply_imbalance_area_effect(global_position, 85.0, duration)

func _on_imbalance_stealth_attack(target: Node, duration: float):
	apply_imbalance_stealth_effect(global_position, 120.0, duration)

func _on_silence_attack(target: Node, duration: float):
	apply_silence_effect(target, duration)

func _on_silence_stealth_attack(target: Node, duration: float):
	apply_silence_stealth_effect(global_position, 120.0, duration)

func _on_silence_chance_attack(target: Node, chance: float, duration: float):
	if randf() < chance:
		apply_silence_effect(target, duration)

func _on_pull_to_center_attack(target: Node, force: float):
	# 拉向中心的实现需要更复杂的逻辑
	pass

func _on_reveal_nearby_attack(target: Node, reveal_range: float):
	# 显现周围敌人的实现
	pass

func _on_tornado_attack(target: Node, duration: float):
	apply_tornado_effect(global_position, 85.0, duration)

func _on_imprison_attack(target: Node, duration: float):
	if target.has_method("apply_imprison"):
		target.apply_imprison(duration)

func _on_knockback_on_end_attack(target: Node, force: float):
	# 结束时击退的实现需要特定的效果系统
	pass

func _on_hurricane_attack(target: Node, duration: float, pull_force: float, damage_per_second: float):
	if target.has_method("apply_hurricane"):
		target.apply_hurricane(global_position, duration, pull_force, damage_per_second)

func _on_flying_debuff_attack(target: Node, speed_reduction: float, attack_speed_reduction: float):
	if target.has_method("is_flying") and target.is_flying():
		apply_flying_debuff_effect(global_position, 100.0, speed_reduction, attack_speed_reduction)

func _on_exile_attack(target: Node, duration: float):
	apply_exile_effect(target, duration)

# 风元素定时器方法
func _start_attack_speed_aura_timer(bonus: float, range: float):
	var timer = Timer.new()
	timer.name = "AttackSpeedAuraTimer"
	timer.wait_time = 1.0  # 每秒应用一次
	timer.autostart = true
	timer.timeout.connect(_on_attack_speed_aura_tick.bind(bonus, range))
	add_child(timer)

func _on_attack_speed_aura_tick(bonus: float, range: float):
	apply_attack_speed_aura_effect(global_position, range, bonus)

func _start_ally_attack_speed_timer(bonus: float, range: float):
	var timer = Timer.new()
	timer.name = "AllyAttackSpeedTimer"
	timer.wait_time = 1.0  # 每秒应用一次
	timer.autostart = true
	timer.timeout.connect(_on_ally_attack_speed_tick.bind(bonus, range))
	add_child(timer)

func _on_ally_attack_speed_tick(bonus: float, range: float):
	apply_attack_speed_aura_effect(global_position, range, bonus)

# 光元素事件处理方法
func _on_blind_attack(target: Node, duration: float, miss_chance: float):
	apply_blind_effect(target, duration, miss_chance)

func _on_purify_attack(target: Node, duration: float, heal_amount: float, energy_return: float):
	apply_purify_effect(target, duration, heal_amount, energy_return)
	# 如果设置了能量返还，返还能量到自身
	if energy_return > 0:
		apply_purify_energy_return_effect(self, energy_return)

func _on_judgment_attack(target: Node, duration: float, damage_multiplier: float):
	apply_judgment_effect(target, duration, damage_multiplier)

# 光元素定时器方法
func _start_heal_towers_timer(heal_amount: float, radius: float):
	var timer = Timer.new()
	timer.name = "HealTowersTimer"
	timer.wait_time = 2.0  # 每2秒治疗一次
	timer.autostart = true
	timer.timeout.connect(_on_heal_towers_tick.bind(heal_amount, radius))
	add_child(timer)

func _on_heal_towers_tick(heal_amount: float, radius: float):
	heal_friendly_towers_effect(global_position, radius, heal_amount)

# 辅助方法
func get_gem_effect_system() -> GemEffectSystem:
	var tree = get_tree()
	if tree and tree.current_scene:
		return tree.current_scene.get_node_or_null("GemEffectSystem")
	return null

func apply_ice_effect_to_target(target: Node, effect_type: String, duration: float, stacks: int = 1):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_effect(target, effect_type, duration, stacks)

# 土元素效果应用方法
func apply_earth_effect_to_target(target: Node, effect_type: String, duration: float, stacks: int = 1):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_effect(target, effect_type, duration, stacks)

# 应用重压区域效果
func apply_weight_area_effect(center: Vector2, radius: float, stacks: int = 1, duration: float = 4.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_weight_area(center, radius, stacks, duration)

# 应用石化效果（带几率）
func apply_chance_petrify_effect(target: Node, chance: float, duration: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_chance_petrify(target, chance, duration)

# 应用破甲弹射效果
func apply_armor_break_on_bounce_effect(target: Node, stacks: int = 1, duration: float = 5.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_armor_break_on_bounce(target, stacks, duration)

# 应用重压效果到所有地面单位
func apply_weight_all_ground_effect(stacks: int = 1, duration: float = 4.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_weight_all_ground(stacks, duration)

# 风元素效果应用方法
func apply_wind_effect_to_target(target: Node, effect_type: String, duration: float, stacks: int = 1):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_effect(target, effect_type, duration, stacks)

# 应用失衡区域效果
func apply_imbalance_area_effect(center: Vector2, radius: float, duration: float = 2.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_imbalance_area(center, radius, duration)

# 应用失衡效果到隐身单位
func apply_imbalance_stealth_effect(center: Vector2, radius: float, duration: float = 2.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_imbalance_stealth(center, radius, duration)

# 应用沉默效果
func apply_silence_effect(target: Node, duration: float = 3.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_silence(target, duration)

# 应用沉默效果到隐身单位
func apply_silence_stealth_effect(center: Vector2, radius: float, duration: float = 3.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_silence_stealth(center, radius, duration)

# 应用击退效果
func apply_knockback_effect(target: Node, force: float = 150.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_knockback(target, force)

# 应用范围击退效果
func apply_knockback_all_effect(center: Vector2, radius: float, force: float = 200.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_knockback_all(center, radius, force)

# 应用飞行单位减益效果
func apply_flying_debuff_effect(center: Vector2, radius: float, speed_reduction: float = 0.2, attack_speed_reduction: float = 0.2):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_flying_debuff(center, radius, speed_reduction, attack_speed_reduction)

# 应用放逐效果
func apply_exile_effect(target: Node, duration: float = 8.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_exile(target, duration)

# 应用龙卷风效果
func apply_tornado_effect(center: Vector2, radius: float, duration: float = 4.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_tornado(center, radius, duration)

# 应用飓风效果
func apply_hurricane_effect(center: Vector2, radius: float, duration: float = 5.0, pull_force: float = 50.0, damage_per_second: float = 20.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_hurricane(center, radius, duration, pull_force, damage_per_second)

# 应用攻击速度光环效果
func apply_attack_speed_aura_effect(center: Vector2, radius: float, speed_bonus: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_attack_speed_aura(center, radius, speed_bonus)

# 移除攻击速度光环效果
func remove_attack_speed_aura_effect(center: Vector2, radius: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.remove_attack_speed_aura(center, radius)

# 应用弹射结束时的额外伤害
func apply_bonus_damage_on_end_effect(target: Node, base_damage: float, damage_multiplier: float = 0.20):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_bonus_damage_on_end(target, base_damage, damage_multiplier)

# 应用余震效果
func apply_aftershock_effect(center: Vector2, radius: float, damage_multiplier: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_aftershock(center, radius, damage_multiplier)

# 应用最大生命值百分比伤害
func apply_max_hp_damage_effect(target: Node, percentage: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_max_hp_damage(target, percentage)

# 应用护盾效果到友方塔
func apply_tower_shield_effect(tower: Node, shield_amount: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_tower_shield(tower, shield_amount)

# 应用永久重压领域
func apply_permanent_weight_field_effect(center: Vector2, radius: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_permanent_weight_field(center, radius)

# 光元素效果应用方法
func apply_light_effect_to_target(target: Node, effect_type: String, duration: float, stacks: int = 1):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_effect(target, effect_type, duration, stacks)

# 应用致盲效果
func apply_blind_effect(target: Node, duration: float = 1.5, miss_chance: float = 0.50):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_blind(target, duration, miss_chance)

# 应用净化效果
func apply_purify_effect(target: Node, duration: float = 0.0, heal_amount: float = 0.0, energy_return: float = 0.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_purify(target, duration, heal_amount, energy_return)

# 应用审判效果
func apply_judgment_effect(target: Node, duration: float = 5.0, damage_multiplier: float = 1.20):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_judgment(target, duration, damage_multiplier)

# 应用致盲区域效果
func apply_blind_area_effect(center: Vector2, radius: float, duration: float = 1.5):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_blind_area(center, radius, duration)

# 应用净化区域效果
func apply_purify_area_effect(center: Vector2, radius: float, heal_amount: float = 0.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_purify_area(center, radius, heal_amount)

# 应用审判区域效果
func apply_judgment_area_effect(center: Vector2, radius: float, duration: float = 5.0):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_judgment_area(center, radius, duration)

# 应用致盲到隐身单位
func apply_blind_stealth_effect(center: Vector2, radius: float, duration: float = 1.5):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_blind_stealth(center, radius, duration)

# 应用治疗到友方塔
func heal_friendly_towers_effect(center: Vector2, radius: float, heal_amount: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.heal_friendly_towers(center, radius, heal_amount)

# 应用能量返还到友方塔
func restore_energy_to_towers_effect(center: Vector2, radius: float, energy_amount: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.restore_energy_to_towers(center, radius, energy_amount)

# 应用神圣伤害
func apply_holy_damage_effect(target: Node, base_damage: float) -> float:
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		return gem_effect_system.apply_holy_damage(target, base_damage)
	return base_damage

# 应用审判扩散效果
func apply_judgment_spread_effect(death_center: Vector2, radius: float, base_damage: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_judgment_spread(death_center, radius, base_damage)

# 应用净化能量返还
func apply_purify_energy_return_effect(tower: Node, energy_amount: float):
	var gem_effect_system = get_gem_effect_system()
	if gem_effect_system:
		gem_effect_system.apply_purify_energy_return(tower, energy_amount)

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

## Combat Type and Target System Methods

# Check if this tower can target a specific enemy
func can_target_enemy(enemy: Node) -> bool:
	if not is_instance_valid(enemy):
		return false
	
	# Check enemy flight status
	var is_flying = false
	if enemy.has_method("is_flying"):
		is_flying = enemy.is_flying()
	elif enemy.has_meta("is_flying"):
		is_flying = enemy.get_meta("is_flying")
	
	# Apply target type filtering
	match target_type:
		TargetType.GROUND_ONLY:
			return not is_flying
		TargetType.AIR_ONLY:
			return is_flying
		TargetType.BOTH:
			return true
		_:
			return true

# Setup blocking collision for melee towers
func setup_blocking_collision() -> void:
	if not can_block_path:
		return
	
	if blocking_collision:
		blocking_collision.queue_free()
	
	blocking_collision = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Make blocking area smaller than full tile to allow some passage
	shape.size = Vector2(20, 15)  # Partial road blocking
	collision_shape.shape = shape
	blocking_collision.add_child(collision_shape)
	
	# Set collision layers for enemy interaction
	blocking_collision.collision_layer = 8  # Blocking layer
	blocking_collision.collision_mask = 0   # Don't detect anything
	
	add_child(blocking_collision)
	is_blocking = true

# Remove blocking collision
func remove_blocking_collision() -> void:
	if blocking_collision and is_instance_valid(blocking_collision):
		blocking_collision.queue_free()
		blocking_collision = null
	is_blocking = false

# Take damage (for blocking towers)
func take_damage(damage_amount: float) -> void:
	if not can_block_path or not is_alive:
		return
	
	current_health -= damage_amount
	current_health = max(0, current_health)
	
	# Update visual health indicator
	update_health_display()
	
	if current_health <= 0:
		tower_destroyed()

# Update health display
func update_health_display() -> void:
	if not can_block_path:
		return
	
	var health_percentage = current_health / max_health
	if health_percentage > 0.6:
		modulate = Color.WHITE
	elif health_percentage > 0.3:
		modulate = Color.YELLOW
	else:
		modulate = Color.RED

# Handle tower destruction
func tower_destroyed() -> void:
	is_alive = false
	current_target = null
	remove_blocking_collision()
	
	# Visual effects for destruction
	modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	# Start respawn timer
	var respawn_timer = Timer.new()
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)
	respawn_timer.start()
	
	print("Blocking tower destroyed! Respawning in ", respawn_time, " seconds")

# Handle respawn
func _on_respawn_timer_timeout() -> void:
	is_alive = true
	current_health = max_health
	modulate = Color.WHITE
	
	if can_block_path:
		setup_blocking_collision()
	
	print("Blocking tower respawned!")


# Shadow Effect Setup Methods

func _setup_corrosion_effect(effect_data: Dictionary):
	var stacks = effect_data.get("stacks", 1)
	if current_target:
		apply_corrosion_effect_to_target(current_target, stacks)

func _setup_life_steal_effect(effect_data: Dictionary):
	var percentage = effect_data.get("percentage", 0.30)
	life_steal_percentage = percentage

func _setup_healing_reduction_effect(effect_data: Dictionary):
	var reduction_percent = effect_data.get("reduction_percent", 0.50)
	if current_target:
		apply_healing_reduction_to_target(current_target, reduction_percent)

func _setup_death_contagion_effect(effect_data: Dictionary):
	var contagion_radius = effect_data.get("contagion_radius", 80.0)
	var contagion_stacks = effect_data.get("contagion_stacks", 1)
	death_contagion_radius = contagion_radius
	death_contagion_stacks = contagion_stacks

func _setup_chance_fear_effect(effect_data: Dictionary):
	var chance = effect_data.get("chance", 0.50)
	var duration = effect_data.get("duration", 2.0)
	fear_chance = chance
	fear_duration = duration

func _setup_fear_area_effect(effect_data: Dictionary):
	var radius = effect_data.get("radius", 85.0)
	var duration = effect_data.get("duration", 2.0)
	fear_area_radius = radius
	fear_area_duration = duration

func _setup_no_healing_effect(effect_data: Dictionary):
	var duration = effect_data.get("duration", 5.0)
	no_healing_duration = duration

func _setup_channel_life_drain_effect(effect_data: Dictionary):
	var drain_percent = effect_data.get("drain_percent", 0.15)
	var channel_duration = effect_data.get("channel_duration", 3.0)
	channel_drain_percent = drain_percent
	channel_drain_duration = channel_duration

func _setup_fear_area_detection_effect(effect_data: Dictionary):
	var radius = effect_data.get("radius", 120.0)
	var duration = effect_data.get("duration", 2.0)
	fear_detection_radius = radius
	fear_detection_duration = duration

func _setup_global_life_steal_effect(effect_data: Dictionary):
	var percentage = effect_data.get("percentage", 0.10)
	var duration = effect_data.get("duration", 3.0)
	global_life_steal_percentage = percentage
	global_life_steal_duration = duration

func _setup_corrosion_aura_effect(effect_data: Dictionary):
	var radius = effect_data.get("radius", 95.0)
	var stacks = effect_data.get("stacks", 1)
	var interval = effect_data.get("interval", 2.0)
	corrosion_aura_radius = radius
	corrosion_aura_stacks = stacks
	corrosion_aura_interval = interval

func _setup_life_drain_aura_effect(effect_data: Dictionary):
	var radius = effect_data.get("radius", 95.0)
	var drain_percent = effect_data.get("drain_percent", 0.05)
	life_drain_aura_radius = radius
	life_drain_aura_percentage = drain_percent

func _setup_permanent_stat_steal_effect(effect_data: Dictionary):
	var stat = effect_data.get("stat", "damage")
	var steal_amount = effect_data.get("steal_amount", 1.0)
	permanent_steal_stat = stat
	permanent_steal_amount = steal_amount

func _setup_area_life_steal_effect(effect_data: Dictionary):
	var radius = effect_data.get("radius", 100.0)
	var percentage = effect_data.get("percentage", 0.15)
	area_life_steal_radius = radius
	area_life_steal_percentage = percentage

func _setup_life_cost_effect(effect_data: Dictionary):
	var percentage = effect_data.get("percentage", 0.10)
	life_cost_percentage = percentage

func _setup_damage_multiplier_effect(effect_data: Dictionary):
	var multiplier = effect_data.get("multiplier", 3.0)
	damage_multiplier = multiplier

func _setup_fear_on_hit_effect(effect_data: Dictionary):
	var chance = effect_data.get("chance", 0.30)
	var duration = effect_data.get("duration", 2.0)
	fear_on_hit_chance = chance
	fear_on_hit_duration = duration

func _setup_stealth_life_drain_effect(effect_data: Dictionary):
	var drain_percent = effect_data.get("drain_percent", 0.20)
	var duration = effect_data.get("duration", 3.0)
	stealth_life_drain_percent = drain_percent
	stealth_life_drain_duration = duration

func _setup_stat_steal_on_death_effect(effect_data: Dictionary):
	var attack_steal = effect_data.get("attack_steal", 0.10)
	var defense_steal = effect_data.get("defense_steal", 0.10)
	death_stat_steal_attack = attack_steal
	death_stat_steal_defense = defense_steal

func _setup_targeting_priority_effect(effect_data: Dictionary):
	var priority = effect_data.get("priority", "unfeared")
	var multiplier = effect_data.get("priority_multiplier", 2.0)
	targeting_priority = priority
	targeting_priority_multiplier = multiplier

# Shadow Effect Variables
var life_steal_percentage: float = 0.0
var fear_chance: float = 0.50
var fear_duration: float = 2.0
var death_contagion_radius: float = 80.0
var death_contagion_stacks: int = 1
var fear_area_radius: float = 85.0
var fear_area_duration: float = 2.0
var no_healing_duration: float = 5.0
var channel_drain_percent: float = 0.15
var channel_drain_duration: float = 3.0
var fear_detection_radius: float = 120.0
var fear_detection_duration: float = 2.0
var global_life_steal_percentage: float = 0.10
var global_life_steal_duration: float = 3.0
var corrosion_aura_radius: float = 95.0
var corrosion_aura_stacks: int = 1
var corrosion_aura_interval: float = 2.0
var life_drain_aura_radius: float = 95.0
var life_drain_aura_percentage: float = 0.05
var permanent_steal_stat: String = "damage"
var permanent_steal_amount: float = 1.0
var area_life_steal_radius: float = 100.0
var area_life_steal_percentage: float = 0.15
var life_cost_percentage: float = 0.10
var damage_multiplier: float = 3.0
var fear_on_hit_chance: float = 0.30
var fear_on_hit_duration: float = 2.0
var stealth_life_drain_percent: float = 0.20
var stealth_life_drain_duration: float = 3.0
var death_stat_steal_attack: float = 0.10
var death_stat_steal_defense: float = 0.10
var targeting_priority: String = "unfeared"
var targeting_priority_multiplier: float = 2.0

# Shadow Effect Application Methods

func apply_corrosion_effect_to_target(target: Node, stacks: int = 1):
	if target and target.has_method("set_corrosion_stacks"):
		target.set_corrosion_stacks(stacks)

func apply_healing_reduction_to_target(target: Node, reduction_percent: float):
	if target and target.has_method("apply_healing_reduction"):
		target.apply_healing_reduction(reduction_percent)

func apply_fear_effect_to_target(target: Node):
	if target and target.has_method("set_feared"):
		target.set_feared(true, fear_chance, fear_duration)

func apply_life_drain_effect_to_target(target: Node, drain_percent: float):
	if target and target.has_method("apply_life_drain"):
		target.apply_life_drain(drain_percent)

func apply_no_healing_to_target(target: Node):
	if target and target.has_method("set_no_healing"):
		target.set_no_healing(true, no_healing_duration)
