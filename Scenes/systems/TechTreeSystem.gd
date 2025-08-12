class_name TechTreeSystem
extends Node

signal tech_unlocked(tech_id: String)
signal tech_purchase_failed(tech_id: String, reason: String)

var unlocked_techs: Array[String] = []

func _ready():
	load_tech_progress()
	# 自动解锁所有免费的科技
	for tech_id in Data.tech_tree.keys():
		var tech_data = Data.tech_tree[tech_id]
		if tech_data.cost == 0:
			unlock_tech(tech_id)

func can_unlock_tech(tech_id: String) -> bool:
	if not Data.tech_tree.has(tech_id):
		return false
	
	var tech_data = Data.tech_tree[tech_id]
	
	# Check if already unlocked
	if tech_data.unlocked or tech_id in unlocked_techs:
		return false
	
	# Check requirements
	for requirement in tech_data.requirements:
		if not is_tech_unlocked(requirement):
			return false
	
	# Check cost
	if Globals.currentMap and Globals.currentMap.gold < tech_data.cost:
		return false
	
	return true

func unlock_tech(tech_id: String) -> bool:
	# For free techs, automatically unlock them
	var tech_data = Data.tech_tree[tech_id]
	if tech_data.cost == 0:
		if not is_tech_unlocked(tech_id):
			unlocked_techs.append(tech_id)
			tech_data.unlocked = true
			apply_tech_effects(tech_id)
			tech_unlocked.emit(tech_id)
			save_tech_progress()
		return true
	
	if not can_unlock_tech(tech_id):
		tech_purchase_failed.emit(tech_id, "Requirements not met")
		return false
	
	# Deduct cost
	if Globals.currentMap:
		Globals.currentMap.gold -= tech_data.cost
	
	# Mark as unlocked
	unlocked_techs.append(tech_id)
	tech_data.unlocked = true
	
	apply_tech_effects(tech_id)
	tech_unlocked.emit(tech_id)
	save_tech_progress()
	return true

func is_tech_unlocked(tech_id: String) -> bool:
	if tech_id in unlocked_techs:
		return true
	var tech_data = Data.tech_tree.get(tech_id) if Data.tech_tree.has(tech_id) else {}
	return tech_data.get("unlocked") if tech_data.has("unlocked") else false

func apply_tech_effects(tech_id: String):
	match tech_id:
		"charge_system_unlock":
			enable_charge_system()
		"summon_stones_unlock":
			enable_summon_stones()

func enable_charge_system():
	# Enable charge system functionality
	var charge_system = get_tree().current_scene.get_node_or_null("ChargeSystem")
	if charge_system:
		charge_system.set_process(true)

func enable_summon_stones():
	# Enable summon stone functionality  
	var summon_system = get_tree().current_scene.get_node_or_null("SummonStoneSystem")
	if summon_system:
		summon_system.set_process(true)

func save_tech_progress():
	var save_data = {
		"unlocked_techs": unlocked_techs
	}
	var file = FileAccess.open("user://tech_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_tech_progress():
	if FileAccess.file_exists("user://tech_progress.json"):
		var file = FileAccess.open("user://tech_progress.json", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				var save_data = json.data
				unlocked_techs = save_data.get("unlocked_techs") if save_data.has("unlocked_techs") else []
				# Apply unlocked tech effects
				for tech_id in unlocked_techs:
					apply_tech_effects(tech_id)