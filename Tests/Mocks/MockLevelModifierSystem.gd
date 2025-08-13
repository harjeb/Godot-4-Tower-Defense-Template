extends Node
class_name MockLevelModifierSystem

## Mock Level Modifier System for testing
## Simulates level modifier functionality

signal modifier_applied(target: Node, modifier: Dictionary)
signal modifier_expired(target: Node, modifier: Dictionary)
signal modifier_ui_update(modifiers: Array)
signal modifiers_cleaned()

var active_modifiers: Dictionary = {}  # target_id -> [modifiers]
var modifier_effects: Dictionary = {}  # modifier_id -> effect_data
var level_modifiers: Array = []

func _ready():
	# Initialize mock modifier data
	initialize_modifier_data()

func initialize_modifier_data():
	"""Initialize mock modifier effect data"""
	modifier_effects = {
		"hero_damage_boost": {
			"stat": "damage",
			"multiplier": 1.25,
			"duration": -1
		},
		"hero_hp_boost": {
			"stat": "max_hp", 
			"multiplier": 1.15,
			"duration": -1
		},
		"enemy_hp_reduction": {
			"stat": "hp",
			"multiplier": 0.85,
			"duration": -1
		},
		"skill_cooldown_reduction": {
			"stat": "cooldown",
			"multiplier": 0.8,
			"duration": -1
		}
	}

func generate_modifiers_for_level(level: int) -> Array:
	"""Generate random modifiers for given level"""
	var modifiers = []
	var count = get_modifier_count_for_level(level)
	
	var available_modifiers = get_available_modifiers()
	for i in range(count):
		if available_modifiers.size() > 0:
			var index = randi() % available_modifiers.size()
			var modifier = available_modifiers[index].duplicate(true)
			modifier.level = level
			modifier.duration = get_modifier_duration(modifier)
			modifiers.append(modifier)
	
	level_modifiers = modifiers
	return modifiers

func get_modifier_count_for_level(level: int) -> int:
	"""Get number of modifiers to generate for level"""
	if level == 1:
		return 1
	elif level < 10:
		return 1 if randf() > 0.5 else 2
	else:
		return 2

func get_available_modifiers() -> Array:
	"""Get all available modifiers"""
	var modifiers = []
	
	# Add positive modifiers
	if Data.level_modifiers.has("positive"):
		modifiers.append_array(Data.level_modifiers.positive)
	
	# Add negative modifiers  
	if Data.level_modifiers.has("negative"):
		modifiers.append_array(Data.level_modifiers.negative)
	
	# Add neutral modifiers
	if Data.level_modifiers.has("neutral"):
		modifiers.append_array(Data.level_modifiers.neutral)
	
	return modifiers

func get_modifier_duration(modifier: Dictionary) -> float:
	"""Get duration for modifier based on type"""
	match modifier.type:
		"positive":
			return -1  # Permanent
		"negative":
			return -1  # Permanent for game balance
		"neutral":
			return -1  # Permanent
		_:
			return -1

func apply_modifier(target: Node, modifier: Dictionary) -> bool:
	"""Apply modifier to target"""
	if not modifier.has("id"):
		return false
	
	var target_id = target.get_instance_id()
	if not active_modifiers.has(target_id):
		active_modifiers[target_id] = []
	
	# Check if modifier already applied
	for existing_modifier in active_modifiers[target_id]:
		if existing_modifier.id == modifier.id:
			return false
	
	# Apply modifier effects
	if modifier_effects.has(modifier.id):
		var effect = modifier_effects[modifier.id]
		apply_modifier_effect_to_target(target, effect)
	
	modifier.time_remaining = modifier.duration
	active_modifiers[target_id].append(modifier)
	modifier_applied.emit(target, modifier)
	modifier_ui_update.emit(get_active_modifiers_for_target(target))
	
	return true

func apply_modifier_effect_to_target(target: Node, effect: Dictionary):
	"""Apply specific modifier effect to target"""
	if target.has_method("apply_stat_modifier"):
		target.apply_stat_modifier(effect.get("stat"), effect.get("multiplier", 1.0))

func remove_modifier(target: Node, modifier_id: String) -> bool:
	"""Remove modifier from target"""
	var target_id = target.get_instance_id()
	if not active_modifiers.has(target_id):
		return false
	
	for i in range(active_modifiers[target_id].size()):
		if active_modifiers[target_id][i].id == modifier_id:
			var modifier = active_modifiers[target_id][i]
			active_modifiers[target_id].remove_at(i)
			modifier_expired.emit(target, modifier)
			modifier_ui_update.emit(get_active_modifiers_for_target(target))
			return true
	
	return false

func get_active_modifiers_for_target(target: Node) -> Array:
	"""Get active modifiers for target"""
	var target_id = target.get_instance_id()
	return active_modifiers.get(target_id, [])

func has_modifier(target: Node, modifier_id: String) -> bool:
	"""Check if target has specific modifier"""
	var modifiers = get_active_modifiers_for_target(target)
	for modifier in modifiers:
		if modifier.id == modifier_id:
			return true
	return false

func update_modifiers(delta: float):
	"""Update all active modifiers (duration countdown, etc.)"""
	for target_id in active_modifiers:
		var modifiers_to_remove = []
		
		for i in range(active_modifiers[target_id].size()):
			var modifier = active_modifiers[target_id][i]
			
			if modifier.duration > 0:
				modifier.time_remaining -= delta
				if modifier.time_remaining <= 0:
					modifiers_to_remove.append(i)
		
		# Remove expired modifiers
		for i in range(modifiers_to_remove.size() - 1, -1, -1):
			var index = modifiers_to_remove[i]
			var modifier = active_modifiers[target_id][index]
			active_modifiers[target_id].remove_at(index)
			
			# Find target node to emit signal
			var target = get_target_by_id(target_id)
			if target:
				modifier_expired.emit(target, modifier)

func get_target_by_id(target_id: int) -> Node:
	"""Find target node by instance ID"""
	# This is a simplified implementation
	# In reality, would need to track target references
	return null

func cleanup_modifiers_for_target(target: Node):
	"""Clean up all modifiers for specific target"""
	var target_id = target.get_instance_id()
	if active_modifiers.has(target_id):
		active_modifiers[target_id].clear()
		active_modifiers.erase(target_id)
	modifiers_cleaned.emit()

func cleanup_all_modifiers():
	"""Clean up all modifiers"""
	active_modifiers.clear()
	modifiers_cleaned.emit()

func get_modifier_effect(target: Node, modifier_id: String) -> Dictionary:
	"""Get effect data for specific modifier on target"""
	if has_modifier(target, modifier_id) and modifier_effects.has(modifier_id):
		return modifier_effects[modifier_id]
	return {}

func simulate_level_transition():
	"""Simulate level transition - clean up temporary modifiers"""
	for target_id in active_modifiers:
		var modifiers_to_keep = []
		
		for modifier in active_modifiers[target_id]:
			# Keep permanent modifiers (duration == -1)
			if modifier.duration == -1:
				modifiers_to_keep.append(modifier)
		
		active_modifiers[target_id] = modifiers_to_keep
	
	modifiers_cleaned.emit()