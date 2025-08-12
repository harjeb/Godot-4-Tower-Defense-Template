class_name TechPointSystem
extends Node

## Tech Point System for managing talent tree progression
## Handles tech point earning, spending, and talent effect application

signal tech_points_changed(current_points: int)
signal talent_upgraded(talent_id: String, new_level: int)
signal talent_effect_applied(talent_id: String, effect_value: float)

var current_tech_points: int = 0
var talent_levels: Dictionary = {}

func _ready():
	# Initialize all talents to level 0
	for talent_id in Data.tech_tree.keys():
		talent_levels[talent_id] = 0
	load_tech_points()

## Award tech points (called when wave is completed)
func award_tech_points(points: int):
	current_tech_points += points
	tech_points_changed.emit(current_tech_points)
	save_tech_points()

## Check if a talent can be upgraded
func can_upgrade_talent(talent_id: String) -> bool:
	if not Data.tech_tree.has(talent_id):
		return false
	
	var talent_data = Data.tech_tree[talent_id]
	var current_level = talent_levels.get(talent_id, 0)
	
	# Check max level
	if current_level >= talent_data.get("max_level", 1):
		return false
	
	# Check cost
	if current_tech_points < talent_data.cost:
		return false
	
	# Check requirements
	for requirement in talent_data.get("requirements", []):
		if talent_levels.get(requirement, 0) == 0:
			return false
	
	return true

## Upgrade a talent
func upgrade_talent(talent_id: String) -> bool:
	if not can_upgrade_talent(talent_id):
		return false
	
	var talent_data = Data.tech_tree[talent_id]
	
	# Deduct cost
	current_tech_points -= talent_data.cost
	
	# Increase level
	var old_level = talent_levels.get(talent_id, 0)
	talent_levels[talent_id] = old_level + 1
	
	# Apply effect
	apply_talent_effect(talent_id)
	
	# Emit signals
	tech_points_changed.emit(current_tech_points)
	talent_upgraded.emit(talent_id, talent_levels[talent_id])
	
	save_tech_points()
	return true

## Apply talent effects to the game systems
func apply_talent_effect(talent_id: String):
	var level = talent_levels.get(talent_id, 0)
	if level == 0:
		return
	
	match talent_id:
		"damage_boost":
			apply_global_damage_boost(level * 0.10)
		"attack_speed_boost":
			apply_global_speed_boost(level * 0.08)
		"range_boost":
			apply_global_range_boost(level * 0.15)
		"da_chance_boost":
			apply_global_da_boost(level * 0.05)
		"ta_chance_boost":
			apply_global_ta_boost(level * 0.03)
		"charge_speed_boost":
			apply_charge_speed_boost(level * 0.50)
		"economic_boost":
			apply_economic_boost(level * 0.20)
		"wave_preparation":
			apply_wave_preparation_boost(level * 10.0)
		"projectile_speed_boost":
			apply_projectile_speed_boost(level * 0.25)

## Apply all talent effects (called on game start)
func apply_all_talent_effects():
	for talent_id in talent_levels.keys():
		if talent_levels[talent_id] > 0:
			apply_talent_effect(talent_id)

## Get talent level
func get_talent_level(talent_id: String) -> int:
	return talent_levels.get(talent_id, 0)

## Get current tech points
func get_tech_points() -> int:
	return current_tech_points

## TALENT EFFECT APPLICATION METHODS

func apply_global_damage_boost(multiplier: float):
	var all_towers = get_all_towers()
	for tower in all_towers:
		if is_instance_valid(tower):
			tower.passive_damage_bonus += multiplier
	talent_effect_applied.emit("damage_boost", multiplier)

func apply_global_speed_boost(multiplier: float):
	var all_towers = get_all_towers()
	for tower in all_towers:
		if is_instance_valid(tower):
			tower.passive_speed_bonus += multiplier
	talent_effect_applied.emit("attack_speed_boost", multiplier)

func apply_global_range_boost(multiplier: float):
	var all_towers = get_all_towers()
	for tower in all_towers:
		if is_instance_valid(tower):
			tower.attack_range *= (1.0 + multiplier)
	talent_effect_applied.emit("range_boost", multiplier)

func apply_global_da_boost(bonus: float):
	var all_towers = get_all_towers()
	for tower in all_towers:
		if is_instance_valid(tower):
			tower.passive_da_bonus += bonus
	talent_effect_applied.emit("da_chance_boost", bonus)

func apply_global_ta_boost(bonus: float):
	var all_towers = get_all_towers()
	for tower in all_towers:
		if is_instance_valid(tower):
			tower.passive_ta_bonus += bonus
	talent_effect_applied.emit("ta_chance_boost", bonus)

func apply_charge_speed_boost(multiplier: float):
	# This would need to be integrated with the charge system
	var charge_system = get_tree().current_scene.get_node_or_null("ChargeSystem")
	if charge_system and charge_system.has_method("set_charge_multiplier"):
		charge_system.set_charge_multiplier(1.0 + multiplier)
	talent_effect_applied.emit("charge_speed_boost", multiplier)

func apply_economic_boost(multiplier: float):
	# Store economic boost for enemy kill rewards
	if not Globals.has_method("set_economic_boost"):
		Globals.set("economic_boost_multiplier", 1.0 + multiplier)
	talent_effect_applied.emit("economic_boost", multiplier)

func apply_wave_preparation_boost(additional_time: float):
	# This will be used by the wave countdown system
	if not Globals.has_method("set_wave_preparation_time"):
		Globals.set("wave_preparation_bonus", additional_time)
	talent_effect_applied.emit("wave_preparation", additional_time)

func apply_projectile_speed_boost(multiplier: float):
	# Store projectile speed boost globally for projectile turrets
	Globals.set("projectile_speed_boost", 1.0 + multiplier)
	talent_effect_applied.emit("projectile_speed_boost", multiplier)

## Helper function to get all towers
func get_all_towers() -> Array[Turret]:
	var towers: Array[Turret] = []
	var turret_nodes = get_tree().get_nodes_in_group("turret")
	for turret in turret_nodes:
		if turret is Turret and turret.deployed:
			towers.append(turret)
	return towers

## Save/Load system
func save_tech_points():
	var save_data = {
		"tech_points": current_tech_points,
		"talent_levels": talent_levels
	}
	var file = FileAccess.open("user://tech_points.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_tech_points():
	if FileAccess.file_exists("user://tech_points.json"):
		var file = FileAccess.open("user://tech_points.json", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				var save_data = json.data
				current_tech_points = save_data.get("tech_points", 0)
				talent_levels = save_data.get("talent_levels", {})
				
				# Ensure all talents exist in dictionary
				for talent_id in Data.tech_tree.keys():
					if not talent_levels.has(talent_id):
						talent_levels[talent_id] = 0
				
				# Apply existing talent effects
				call_deferred("apply_all_talent_effects")