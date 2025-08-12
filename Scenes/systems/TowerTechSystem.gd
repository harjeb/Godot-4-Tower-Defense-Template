class_name TowerTechSystem
extends Node

## Tower Technology System for individual tower progression
## Manages tower tech tree upgrades and specializations

signal tower_tech_upgraded(tower_type: String, tech_id: String)
signal tower_tech_unlocked(tower_type: String, tech_id: String)

# Store unlocked tech for each tower type
var tower_tech_progress: Dictionary = {}

func _ready():
	load_tower_tech_progress()
	initialize_base_techs()

func initialize_base_techs():
	# Initialize all base techs (level 1) as unlocked
	for tower_type in Data.tower_tech_tree.keys():
		if not tower_tech_progress.has(tower_type):
			tower_tech_progress[tower_type] = {}
		tower_tech_progress[tower_type]["1"] = true

## Check if a tower tech can be unlocked
func can_unlock_tower_tech(tower_type: String, tech_id: String) -> bool:
	if not Data.tower_tech_tree.has(tower_type):
		return false
	
	var tech_data = {}
	if Data.tower_tech_tree[tower_type].has(tech_id):
		tech_data = Data.tower_tech_tree[tower_type].get(tech_id)
	if tech_data.is_empty():
		return false
	
	# Check if already unlocked
	if is_tower_tech_unlocked(tower_type, tech_id):
		return false
	
	# Check parent requirement
	var parent = ""
	if tech_data.has("parent"):
		parent = tech_data.get("parent")
	if parent != "" and not is_tower_tech_unlocked(tower_type, parent):
		return false
	
	# Check cost (using global tech points)
	var tech_point_system = get_tech_point_system()
	if tech_point_system:
		return tech_point_system.get_tech_points() >= tech_data.cost
	
	return false

## Unlock a tower tech
func unlock_tower_tech(tower_type: String, tech_id: String) -> bool:
	if not can_unlock_tower_tech(tower_type, tech_id):
		return false
	
	var tech_data = Data.tower_tech_tree[tower_type][tech_id]
	
	# Deduct cost from tech point system
	var tech_point_system = get_tech_point_system()
	if tech_point_system:
		var current_points = tech_point_system.get_tech_points()
		if current_points >= tech_data.cost:
			# Manually deduct points (since TechPointSystem doesn't have spend method)
			tech_point_system.current_tech_points -= tech_data.cost
			tech_point_system.tech_points_changed.emit(tech_point_system.current_tech_points)
			tech_point_system.save_tech_points()
	
	# Mark as unlocked
	if not tower_tech_progress.has(tower_type):
		tower_tech_progress[tower_type] = {}
	tower_tech_progress[tower_type][tech_id] = true
	
	save_tower_tech_progress()
	tower_tech_unlocked.emit(tower_type, tech_id)
	return true

## Check if a tower tech is unlocked
func is_tower_tech_unlocked(tower_type: String, tech_id: String) -> bool:
	var tower_data = {}
	if tower_tech_progress.has(tower_type):
		tower_data = tower_tech_progress.get(tower_type)
	
	if tower_data.has(tech_id):
		return tower_data.get(tech_id)
	return false

## Get the current tech level of a tower type
func get_tower_tech_level(tower_type: String) -> int:
	if not tower_tech_progress.has(tower_type):
		return 1
	
	# Find the highest unlocked tech level
	var max_level = 1
	for tech_id in tower_tech_progress[tower_type].keys():
		if tower_tech_progress[tower_type][tech_id]:
			if tech_id.begins_with("3"):
				max_level = 3
			elif tech_id.begins_with("2"):
				max_level = max(max_level, 2)
	
	return max_level

## Get current tech specialization of a tower
func get_tower_tech_specialization(tower_type: String) -> String:
	if not tower_tech_progress.has(tower_type):
		return "1"
	
	# Find the unlocked specialization
	for tech_id in tower_tech_progress[tower_type].keys():
		if tower_tech_progress[tower_type][tech_id] and tech_id != "1":
			return tech_id
	
	return "1"

## Get available tech options for a tower type
func get_available_tech_options(tower_type: String) -> Array[String]:
	var options: Array[String] = []
	
	if not Data.tower_tech_tree.has(tower_type):
		return options
	
	for tech_id in Data.tower_tech_tree[tower_type].keys():
		if tech_id != "name" and can_unlock_tower_tech(tower_type, tech_id):
			options.append(tech_id)
	
	return options

## Get tech bonuses for a specific tower tech
func get_tech_bonuses(tower_type: String, tech_id: String) -> Dictionary:
	if not Data.tower_tech_tree.has(tower_type):
		return {}
	
	var tech_data = {}
	if Data.tower_tech_tree[tower_type].has(tech_id):
		tech_data = Data.tower_tech_tree[tower_type].get(tech_id)
	
	if tech_data.has("bonuses"):
		return tech_data.get("bonuses")
	return {}

## Apply tech bonuses to a tower
func apply_tech_bonuses_to_tower(tower):
	if not tower or not tower.deployed:
		return
	
	var specialization = get_tower_tech_specialization(tower.turret_type)
	var bonuses = get_tech_bonuses(tower.turret_type, specialization)
	
	# Apply bonuses
	for bonus_type in bonuses.keys():
		var bonus_value = bonuses[bonus_type]
		match bonus_type:
			"damage":
				tower.damage *= (1.0 + bonus_value)
			"attack_speed":
				tower.attack_speed *= (1.0 + bonus_value)
			"attack_range":
				tower.attack_range *= (1.0 + bonus_value)
			"da_bonus":
				tower.da_bonus += bonus_value
			"ta_bonus":
				tower.ta_bonus += bonus_value
			"element":
				tower.element = bonus_value
			# Add more bonus types as needed

## Get max gem level a tower can equip
func get_tower_max_gem_level(tower_type: String) -> int:
	var specialization = get_tower_tech_specialization(tower_type)
	if not Data.tower_tech_tree.has(tower_type):
		return 1
	
	var tech_data = {}
	if Data.tower_tech_tree[tower_type].has(specialization):
		tech_data = Data.tower_tech_tree[tower_type].get(specialization)
	
	if tech_data.has("gem_slot_level"):
		return tech_data.get("gem_slot_level")
	return 1

## Check if tower can equip a gem
func can_tower_equip_gem(tower_type: String, gem_level: int) -> bool:
	return gem_level <= get_tower_max_gem_level(tower_type)

## Get tech point system reference
func get_tech_point_system():
	return get_tree().current_scene.get_node_or_null("TechPointSystem")

## Save/Load system
func save_tower_tech_progress():
	var save_data = {
		"tower_tech_progress": tower_tech_progress
	}
	var file = FileAccess.open("user://tower_tech_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_tower_tech_progress():
	if FileAccess.file_exists("user://tower_tech_progress.json"):
		var file = FileAccess.open("user://tower_tech_progress.json", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				var save_data = json.data
				if save_data.has("tower_tech_progress"):
					tower_tech_progress = save_data.get("tower_tech_progress")
