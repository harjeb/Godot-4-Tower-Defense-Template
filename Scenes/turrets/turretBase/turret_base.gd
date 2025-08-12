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
		var turret_data = Data.turrets[value]
		$Sprite2D.texture = load(turret_data["sprite"])
		$Sprite2D.scale = Vector2(turret_data["scale"], turret_data["scale"])
		rotates = turret_data["rotates"]
		element = turret_data.get("element", "neutral")
		turret_category = turret_data.get("turret_category", "")
		da_bonus = turret_data.get("da_bonus", 0.05)
		ta_bonus = turret_data.get("ta_bonus", 0.01)
		passive_effect = turret_data.get("passive_effect", "")
		aoe_type = turret_data.get("aoe_type", "none")
		special_mechanics = turret_data.get("special_mechanics", [])
		for stat in turret_data["stats"].keys():
			set(stat, turret_data["stats"][stat])

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
		$AttackCooldown.wait_time = 1.0/value
var attack_range := 1.0:
	set(value):
		attack_range = value
		$DetectionArea/CollisionShape2D.shape.radius = value
var damage := 1.0
var turret_level := 1

func _process(_delta):
	if not deployed:
		@warning_ignore("standalone_ternary")
		colliding() if $CollisionArea.has_overlapping_areas() else not_colliding()
	elif rotates:
		@warning_ignore("standalone_ternary")
		look_at(current_target.position) if is_instance_valid(current_target) else try_get_closest_target()

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

func _on_detection_area_area_entered(area):
	if deployed and not current_target:
		var area_parent = area.get_parent()
		if area_parent.is_in_group("enemy"):
			# 检查隐身敌人的特殊逻辑
			if area_parent.has_method("get_is_stealthed") and area_parent.get_is_stealthed():
				# 某些炮塔类型可以检测隐身敌人
				if can_detect_stealth():
					current_target = area_parent
			else:
				current_target = area_parent

func can_detect_stealth() -> bool:
	# 光元素炮塔或装备光宝石的炮塔可以检测隐身
	return element == "light" or (equipped_gem.has("element") and equipped_gem.element == "light")

func _on_detection_area_area_exited(area):
	if deployed and current_target == area.get_parent():
		current_target = null
		try_get_closest_target()

func try_get_closest_target():
	if not deployed:
		return
	var closest = 1000
	var closest_area = null
	for area in $DetectionArea.get_overlapping_areas():
		var dist = area.position.distance_to(position)
		if dist < closest:
			closest = dist
			closest_area = area
	if closest_area:
		current_target = closest_area.get_parent()

func open_details_pane():
	if not Globals or not Globals.hud:
		return
		
	var turretDetailsScene := preload("res://Scenes/ui/turretUI/turret_details.tscn")
	var details := turretDetailsScene.instantiate()
	details.turret = self
	draw_range = true
	queue_redraw()
	Globals.hud.add_child(details)
	Globals.hud.open_details_pane = details

func close_details_pane():
	draw_range = false
	queue_redraw()
	if Globals and Globals.hud and is_instance_valid(Globals.hud.open_details_pane):
		Globals.hud.open_details_pane.queue_free()
		Globals.hud.open_details_pane = null

func _on_collision_area_input_event(_viewport, _event, _shape_idx):
	if deployed and Input.is_action_just_pressed("LeftClick"):
		if Globals and Globals.hud and is_instance_valid(Globals.hud.open_details_pane):
			if Globals.hud.open_details_pane.turret == self:
				close_details_pane()
				return
			Globals.hud.open_details_pane.turret.close_details_pane()
		open_details_pane()

func upgrade_turret():
	turret_level += 1
	for upgrade in Data.turrets[turret_type]["upgrades"].keys():
		if Data.turrets[turret_type]["upgrades"][upgrade]["multiplies"]:
			set(upgrade, get(upgrade) * Data.turrets[turret_type]["upgrades"][upgrade]["amount"])
		else:
			set(upgrade, get(upgrade) + Data.turrets[turret_type]["upgrades"][upgrade]["amount"])
	turretUpdated.emit()

func attack():
	if is_instance_valid(current_target):
		pass
	else:
		try_get_closest_target()

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
		passive_da_bonus = bonuses.get("da_bonus", 0.0)
		passive_ta_bonus = bonuses.get("ta_bonus", 0.0)
		passive_damage_bonus = bonuses.get("damage_bonus", 0.0)
		passive_speed_bonus = bonuses.get("speed_bonus", 0.0)

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
func equip_gem(gem_data: Dictionary):
	equipped_gem = gem_data
	if gem_data.has("element"):
		element = gem_data.element
	gem_equipped.emit(gem_data)
	turretUpdated.emit()

func unequip_gem():
	var old_gem = equipped_gem
	equipped_gem = {}
	element = Data.turrets[turret_type].get("element", "neutral")
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
