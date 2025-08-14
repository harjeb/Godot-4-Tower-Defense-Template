class_name PassiveSynergyManager
extends Node

## Passive Synergy Manager for Tower Defense Enhancement System
## Manages tower passive bonuses and synergy effects between towers

signal tower_bonuses_updated(tower: Node2D, bonuses: Dictionary)

# Performance optimization - update frequency
var update_interval: float = 1.0
var update_timer: float = 0.0

func _ready():
	# Connect to global tower signals if available
	if Globals.has_signal("turret_placed"):
		Globals.turret_placed.connect(_on_tower_placed)
	if Globals.has_signal("turret_removed"):
		Globals.turret_removed.connect(_on_tower_removed)

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_all_tower_bonuses()

## Calculate passive bonuses for a specific tower
## @param tower: The tower to calculate bonuses for
## @return: Dictionary with bonus values
func calculate_tower_bonuses(tower: Node2D) -> Dictionary:
	if not is_instance_valid(tower) or not tower.deployed:
		return {}
	
	var bonuses = {
		"da_bonus": 0.0,
		"ta_bonus": 0.0,
		"damage_bonus": 0.0,
		"speed_bonus": 0.0,
		"range_bonus": 0.0
	}
	
	match tower.passive_effect:
		"capture_tower_synergy":
			bonuses = calculate_capture_tower_synergy(tower)
		"attack_speed_aura":
			bonuses = calculate_attack_speed_aura(tower)
		"mage_damage_synergy":
			bonuses = calculate_mage_damage_synergy(tower)
		"stealth_detection":
			bonuses = calculate_stealth_detection_bonus(tower)
		"ta_cooldown_reduction":
			bonuses = calculate_ta_cooldown_reduction(tower)
		"adjacent_tower_boost":
			bonuses = calculate_adjacent_tower_boost(tower)
		"unique_damage_bonus":
			bonuses = calculate_unique_damage_bonus(tower)
		"adjacent_da_ta_boost":
			bonuses = calculate_adjacent_da_ta_boost(tower)
		"slowed_enemy_bonus":
			bonuses = calculate_slowed_enemy_bonus(tower)
	
	return bonuses

## Get all towers within range of a center position
## @param center_position: Center point for range calculation
## @param range: Search radius
## @return: Array of towers within range
func get_towers_in_range(center_position: Vector2, range: float) -> Array:
	var towers_in_range: Array = []
	var all_towers = get_all_deployed_towers()
	
	for tower in all_towers:
		if tower.position.distance_to(center_position) <= range:
			towers_in_range.append(tower)
	
	return towers_in_range

## Get towers adjacent to a specific tower (4-directional)
## @param tower: The center tower
## @return: Array of adjacent towers
func get_adjacent_towers(tower: Node2D) -> Array:
	var adjacent_towers: Array = []
	var all_towers = get_all_deployed_towers()
	
	# Define adjacent positions (4-directional, assuming grid-like placement)
	var adjacent_distance = 64.0  # Adjust based on your grid size
	var adjacent_positions = [
		Vector2(adjacent_distance, 0),
		Vector2(-adjacent_distance, 0),
		Vector2(0, adjacent_distance),
		Vector2(0, -adjacent_distance)
	]
	
	for tower_other in all_towers:
		if tower_other == tower:
			continue
		for adj_pos in adjacent_positions:
			if tower_other.position.distance_to(tower.position + adj_pos) <= adjacent_distance * 0.5:
				adjacent_towers.append(tower_other)
				break
	
	return adjacent_towers

## Get all deployed towers in the scene
func get_all_deployed_towers() -> Array:
	var towers: Array = []
	
	# Try to get towers from Globals
	if Globals.has_method("get_all_towers"):
		towers = Globals.get_all_towers()
	else:
		# Fallback: search using groups
		var turret_nodes = get_tree().get_nodes_in_group("turret")
		for turret in turret_nodes:
			if turret.get_script() and turret.get_script().get_global_name() == "Turret" and turret.get("deployed"):
				towers.append(turret)
	
	return towers

## SPECIFIC PASSIVE EFFECT CALCULATIONS

func calculate_capture_tower_synergy(tower: Node2D) -> Dictionary:
	# Arrow Tower: +10% DA, +5% TA per Capture Tower in range
	var bonuses = {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}
	if tower.turret_type != "arrow_tower":
		return bonuses
	
	var towers_in_range = get_towers_in_range(tower.position, tower.attack_range)
	var capture_tower_count = 0
	
	for other_tower in towers_in_range:
		if other_tower.turret_type == "capture_tower":
			capture_tower_count += 1
	
	bonuses.da_bonus = capture_tower_count * 0.10
	bonuses.ta_bonus = capture_tower_count * 0.05
	return bonuses

func calculate_attack_speed_aura(tower: Node2D) -> Dictionary:
	# Capture Tower: +10% attack speed to all towers in range
	var bonuses = {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}
	if tower.turret_type != "capture_tower":
		return bonuses
	
	# This effect applies to other towers, handled in update_all_tower_bonuses
	return bonuses

func calculate_mage_damage_synergy(tower: Node2D) -> Dictionary:
	# Mage Tower: +10% damage per other Mage Tower
	var bonuses = {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}
	if tower.turret_type != "mage_tower":
		return bonuses
	
	var all_towers = get_all_deployed_towers()
	var other_mage_count = 0
	
	for other_tower in all_towers:
		if other_tower.turret_type == "mage_tower" and other_tower != tower:
			other_mage_count += 1
	
	bonuses.damage_bonus = other_mage_count * 0.10
	return bonuses

func calculate_stealth_detection_bonus(tower: Node2D) -> Dictionary:
	# Detection Tower: No direct bonuses, provides stealth detection
	return {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}

func calculate_ta_cooldown_reduction(tower: Node2D) -> Dictionary:
	# Doomsday Tower: -0.5s CD per TA triggered anywhere (handled globally)
	# This tower gets reduced cooldown when any tower triggers TA
	return {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}

## Handle TA trigger events to reduce Doomsday Tower cooldown
## @param triggering_tower: The tower that triggered TA
func on_ta_triggered(triggering_tower: Node2D):
	# Find all Doomsday Towers and reduce their cooldown by 0.5s
	var all_towers = get_all_deployed_towers()
	
	for tower in all_towers:
		if tower.turret_type == "doomsday_tower" and is_instance_valid(tower):
			# Reduce attack cooldown by 0.5 seconds
			if tower.has_node("AttackCooldown"):
				var cooldown_timer = tower.get_node("AttackCooldown")
				if cooldown_timer is Timer:
					cooldown_timer.wait_time = max(0.1, cooldown_timer.wait_time - 0.5)

func calculate_adjacent_tower_boost(tower: Node2D) -> Dictionary:
	# Pulse Tower: +5% speed, +5% damage to adjacent 2 towers
	var bonuses = {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}
	if tower.turret_type != "pulse_tower":
		return bonuses
	
	# This effect applies to other towers, handled in update_all_tower_bonuses
	return bonuses

func calculate_unique_damage_bonus(tower: Node2D) -> Dictionary:
	# Ricochet Tower: +50% damage when only one exists
	var bonuses = {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}
	if tower.turret_type != "ricochet_tower":
		return bonuses
	
	var all_towers = get_all_deployed_towers()
	var ricochet_count = 0
	
	for other_tower in all_towers:
		if other_tower.turret_type == "ricochet_tower":
			ricochet_count += 1
	
	if ricochet_count == 1:
		bonuses.damage_bonus = 0.50
	
	return bonuses

func calculate_adjacent_da_ta_boost(tower: Node2D) -> Dictionary:
	# Aura Tower: +15% DA, +10% TA to adjacent 2 towers
	var bonuses = {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}
	if tower.turret_type != "aura_tower":
		return bonuses
	
	# This effect applies to other towers, handled in update_all_tower_bonuses
	return bonuses

func calculate_slowed_enemy_bonus(tower: Node2D) -> Dictionary:
	# Weakness Tower: +15% damage vs slowed enemies (context-dependent)
	var bonuses = {"da_bonus": 0.0, "ta_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0}
	if tower.turret_type != "weakness_tower":
		return bonuses
	
	# This would need enemy state checking, implement as needed
	bonuses.damage_bonus = 0.15  # Simplified for now
	return bonuses

## Update bonuses for all towers (performance-optimized)
func update_all_tower_bonuses():
	var all_towers = get_all_deployed_towers()
	
	for tower in all_towers:
		if is_instance_valid(tower):
			var bonuses = calculate_tower_bonuses(tower)
			
			# Apply cross-tower effects
			bonuses = apply_cross_tower_effects(tower, bonuses, all_towers)
			
			# Update tower with new bonuses
			tower.passive_da_bonus = bonuses.get("da_bonus") if bonuses.has("da_bonus") else 0.0
			tower.passive_ta_bonus = bonuses.get("ta_bonus") if bonuses.has("ta_bonus") else 0.0
			tower.passive_damage_bonus = bonuses.get("damage_bonus") if bonuses.has("damage_bonus") else 0.0
			tower.passive_speed_bonus = bonuses.get("speed_bonus") if bonuses.has("speed_bonus") else 0.0
			
			tower_bonuses_updated.emit(tower, bonuses)

## Apply effects from other towers to this tower
func apply_cross_tower_effects(tower: Node2D, base_bonuses: Dictionary, all_towers: Array) -> Dictionary:
	var bonuses = base_bonuses.duplicate()
	
	for other_tower in all_towers:
		if other_tower == tower or not is_instance_valid(other_tower):
			continue
		
		match other_tower.passive_effect:
			"attack_speed_aura":
				if tower.position.distance_to(other_tower.position) <= other_tower.attack_range:
					bonuses.speed_bonus += 0.10
			"adjacent_tower_boost":
				var adjacent_towers = get_adjacent_towers(other_tower)
				if tower in adjacent_towers and adjacent_towers.size() >= 2:
					bonuses.speed_bonus += 0.05
					bonuses.damage_bonus += 0.05
			"adjacent_da_ta_boost":
				var adjacent_towers = get_adjacent_towers(other_tower)
				if tower in adjacent_towers and adjacent_towers.size() >= 2:
					bonuses.da_bonus += 0.15
					bonuses.ta_bonus += 0.10
	
	return bonuses

## Event handlers
func _on_tower_placed(tower: Node2D):
	# Recalculate all bonuses when a tower is placed
	call_deferred("update_all_tower_bonuses")

func _on_tower_removed(tower: Node2D):
	# Recalculate all bonuses when a tower is removed
	call_deferred("update_all_tower_bonuses")