class_name HeroTalentSystem
extends Node

## Hero Talent Management System
## Handles talent progression, selection, and effect application

signal talent_selected(hero: HeroBase, talent_id: String, level: int)
signal talent_effects_applied(hero: HeroBase, talent_id: String)
signal talent_selection_offered(hero: HeroBase, talents: Array[Dictionary])

# Talent system state
var active_talent_effects: Dictionary = {} # hero -> {talent_id: effects}
var talent_selection_queue: Array = [] # Pending talent selections

# Talent level thresholds
const TALENT_LEVELS: Array[int] = [5, 10, 15]

func _ready() -> void:
	# Connect to hero events
	setup_connections()
	
	# Add to global systems
	add_to_group("hero_systems")

func setup_connections() -> void:
	"""Set up system connections"""
	# We'll connect to heroes when they're created via HeroManager
	pass

func connect_to_hero(hero: HeroBase) -> void:
	"""Connect talent system to a specific hero"""
	if not hero:
		return
	
	if hero.has_signal("hero_leveled_up"):
		hero.connect("hero_leveled_up", _on_hero_leveled_up)
	
	# Initialize talent effects storage for this hero
	if not active_talent_effects.has(hero):
		active_talent_effects[hero] = {}

func _on_hero_leveled_up(hero: HeroBase, new_level: int) -> void:
	"""Handle hero level up for talent selection"""
	if not hero or new_level not in TALENT_LEVELS:
		return
	
	# Check if hero already has talent for this level
	if hero.talent_selections.has(new_level):
		return
	
	# Get available talents for this level
	var talent_options = get_talent_options(hero, new_level)
	if talent_options.is_empty():
		push_warning("No talent options available for hero " + hero.hero_type + " at level " + str(new_level))
		return
	
	# Offer talent selection
	hero.available_talents = talent_options
	hero.pending_talent_selection = true
	
	talent_selection_offered.emit(hero, talent_options)

func get_talent_options(hero: HeroBase, level: int) -> Array[Dictionary]:
	"""Get talent options for hero at specific level"""
	if not hero or not Data.hero_talents.has(hero.hero_type):
		return []
	
	var hero_talents = Data.hero_talents[hero.hero_type]
	var level_key = "level_" + str(level)
	
	if not hero_talents.has(level_key):
		return []
	
	return hero_talents[level_key].duplicate(true)

func apply_talent(hero: HeroBase, talent_id: String) -> void:
	"""Apply selected talent to hero"""
	if not hero:
		push_error("Invalid hero for talent application")
		return
	
	# Find talent data
	var talent_data = find_talent_data(hero, talent_id)
	if not talent_data:
		push_error("Talent data not found: " + talent_id)
		return
	
	# Apply talent effects
	apply_talent_effects(hero, talent_data)
	
	# Store talent selection
	hero.talent_selections[hero.current_level] = talent_id
	hero.pending_talent_selection = false
	hero.available_talents.clear()
	
	# Store active effects
	if not active_talent_effects.has(hero):
		active_talent_effects[hero] = {}
	active_talent_effects[hero][talent_id] = talent_data.effects.duplicate(true)
	
	talent_selected.emit(hero, talent_id, hero.current_level)
	talent_effects_applied.emit(hero, talent_id)

func find_talent_data(hero: HeroBase, talent_id: String) -> Dictionary:
	"""Find talent data by ID in hero's talent tree"""
	if not Data.hero_talents.has(hero.hero_type):
		return {}
	
	var hero_talents = Data.hero_talents[hero.hero_type]
	
	# Search through all talent levels
	for level_key in hero_talents.keys():
		var level_talents = hero_talents[level_key]
		for talent in level_talents:
			if talent.id == talent_id:
				return talent
	
	return {}

func apply_talent_effects(hero: HeroBase, talent_data: Dictionary) -> void:
	"""Apply talent effects to hero"""
	if not hero or not talent_data.has("effects"):
		return
	
	var effects = talent_data.effects
	
	# Apply stat modifications
	for effect_key in effects:
		var effect_value = effects[effect_key]
		apply_single_talent_effect(hero, effect_key, effect_value)

func apply_single_talent_effect(hero: HeroBase, effect_key: String, effect_value) -> void:
	"""Apply individual talent effect"""
	match effect_key:
		# Shadow Strike enhancements
		"shadow_strike_attack_count":
			modify_skill_property(hero, "shadow_strike", "attack_count", effect_value, true)
		
		# Charge system modifications
		"charge_generation_multiplier":
			hero.charge_generation_rate *= effect_value
		
		# Flame Armor enhancements  
		"flame_armor_aura_damage":
			modify_skill_property(hero, "flame_armor", "aura_damage", effect_value, false)
		
		# Stat multipliers
		"max_hp_multiplier":
			hero.current_stats["max_hp"] = int(hero.current_stats.get("max_hp", 100) * effect_value)
		"damage_multiplier":
			hero.current_stats["damage"] = int(hero.current_stats.get("damage", 0) * effect_value)
		"defense_multiplier":
			hero.current_stats["defense"] = int(hero.current_stats.get("defense", 0) * effect_value)
		
		# Stat bonuses (additive)
		"defense_bonus":
			hero.current_stats["defense"] = hero.current_stats.get("defense", 0) + effect_value
		"attack_range_multiplier":
			hero.current_stats["attack_range"] = hero.current_stats.get("attack_range", 0) * effect_value
		
		# Flame Phantom enhancements
		"flame_phantom_duration":
			modify_skill_property(hero, "flame_phantom", "duration", effect_value, false)
		"flame_phantom_damage":
			modify_skill_property(hero, "flame_phantom", "phantom_damage", effect_value, false)
		
		# Aura modifications
		"aura_radius_multiplier":
			modify_all_skill_auras(hero, "radius_multiplier", effect_value)
		"aura_burn_chance":
			add_skill_effect_property(hero, "aura_burn_chance", effect_value)
		
		_:
			push_warning("Unknown talent effect: " + effect_key)

func modify_skill_property(hero: HeroBase, skill_id: String, property: String, value, is_additive: bool) -> void:
	"""Modify a specific skill property"""
	var skill = hero.get_skill_by_id(skill_id)
	if not skill:
		return
	
	if not skill.skill_data.has(property):
		skill.skill_data[property] = 0
	
	if is_additive:
		skill.skill_data[property] += value
	else:
		skill.skill_data[property] *= value

func modify_all_skill_auras(hero: HeroBase, property_suffix: String, value) -> void:
	"""Modify aura properties for all skills"""
	for skill in hero.skills:
		if skill.skill_data.has("aura_radius"):
			if property_suffix == "radius_multiplier":
				skill.skill_data["aura_radius"] *= value

func add_skill_effect_property(hero: HeroBase, property: String, value) -> void:
	"""Add new property to all applicable skills"""
	for skill in hero.skills:
		if skill.skill_data.has("aura_radius"):
			skill.skill_data[property] = value

func get_talent_effects(hero: HeroBase) -> Dictionary:
	"""Get all active talent effects for hero"""
	if not active_talent_effects.has(hero):
		return {}
	
	return active_talent_effects[hero].duplicate(true)

func get_hero_talent_summary(hero: HeroBase) -> Dictionary:
	"""Get summary of hero's talents"""
	if not hero:
		return {}
	
	var summary = {
		"selected_talents": hero.talent_selections.duplicate(true),
		"available_levels": [],
		"next_talent_level": 0,
		"pending_selection": hero.pending_talent_selection
	}
	
	# Find next available talent level
	for level in TALENT_LEVELS:
		if not hero.talent_selections.has(level):
			summary.next_talent_level = level
			break
		summary.available_levels.append(level)
	
	return summary

func can_select_talent(hero: HeroBase, talent_id: String) -> bool:
	"""Check if hero can select specific talent"""
	if not hero or not hero.pending_talent_selection:
		return false
	
	if hero.available_talents.is_empty():
		return false
	
	# Check if talent is in available options
	for talent in hero.available_talents:
		if talent.id == talent_id:
			return true
	
	return false

func get_talent_description(talent_data: Dictionary) -> String:
	"""Generate detailed talent description"""
	if not talent_data.has("name") or not talent_data.has("description"):
		return "Unknown talent"
	
	var description = talent_data.name + "\n" + talent_data.description
	
	# Add effect details
	if talent_data.has("effects"):
		description += "\n\nEffects:"
		var effects = talent_data.effects
		for effect_key in effects:
			var effect_value = effects[effect_key]
			description += "\n• " + format_effect_description(effect_key, effect_value)
	
	return description

func format_effect_description(effect_key: String, value) -> String:
	"""Format talent effect for display"""
	match effect_key:
		"shadow_strike_attack_count":
			return "Shadow Strike attacks: +" + str(value)
		"charge_generation_multiplier":
			return "Charge generation: +" + str(int((value - 1.0) * 100)) + "%"
		"flame_armor_aura_damage":
			return "Flame Armor aura damage: x" + str(value)
		"max_hp_multiplier":
			return "Max health: +" + str(int((value - 1.0) * 100)) + "%"
		"defense_bonus":
			return "Defense: +" + str(value)
		"flame_phantom_duration":
			return "Flame Phantom duration: x" + str(value)
		"flame_phantom_damage":
			return "Phantom damage: x" + str(value)
		"aura_radius_multiplier":
			return "Aura radius: +" + str(int((value - 1.0) * 100)) + "%"
		"aura_burn_chance":
			return "Burn chance: " + str(int(value * 100)) + "%"
		_:
			return effect_key + ": " + str(value)

func validate_talent_selection(hero: HeroBase, talent_id: String) -> Dictionary:
	"""Validate talent selection and return result"""
	var result = {
		"valid": false,
		"error": "",
		"talent_data": {}
	}
	
	if not hero:
		result.error = "Invalid hero"
		return result
	
	if not hero.pending_talent_selection:
		result.error = "No pending talent selection"
		return result
	
	if not can_select_talent(hero, talent_id):
		result.error = "Talent not available for selection"
		return result
	
	var talent_data = find_talent_data(hero, talent_id)
	if talent_data.is_empty():
		result.error = "Talent data not found"
		return result
	
	result.valid = true
	result.talent_data = talent_data
	return result

func reset_hero_talents(hero: HeroBase) -> void:
	"""Reset all talents for hero (for testing/respec)"""
	if not hero:
		return
	
	# Clear talent selections
	hero.talent_selections.clear()
	hero.pending_talent_selection = false
	hero.available_talents.clear()
	
	# Remove active effects
	if active_talent_effects.has(hero):
		active_talent_effects.erase(hero)
	
	# Reset hero stats to base values
	hero.setup_hero_data()

func get_talent_tree_for_hero(hero_type: String) -> Dictionary:
	"""Get complete talent tree for hero type"""
	if not Data.hero_talents.has(hero_type):
		return {}
	
	return Data.hero_talents[hero_type].duplicate(true)

func get_talent_recommendations(hero: HeroBase) -> Array[String]:
	"""Get recommended talents for hero based on current state"""
	if not hero or hero.available_talents.is_empty():
		return []
	
	var recommendations: Array[String] = []
	
	# Simple recommendation logic (can be enhanced)
	var current_level = hero.current_level
	
	match current_level:
		5:
			# Early game - focus on core mechanics
			if has_talent_available(hero, "rapid_charge"):
				recommendations.append("rapid_charge")
			else:
				recommendations.append("enhanced_strikes")
		
		10:
			# Mid game - specialization
			if hero.current_stats.get("max_hp", 0) < 600:
				recommendations.append("defensive_stance")
			else:
				recommendations.append("flame_mastery")
		
		15:
			# Late game - power spike
			recommendations.append("phantom_lord") # Usually the better choice
	
	return recommendations

func has_talent_available(hero: HeroBase, talent_id: String) -> bool:
	"""Check if specific talent is available for selection"""
	for talent in hero.available_talents:
		if talent.id == talent_id:
			return true
	return false

func get_talent_statistics() -> Dictionary:
	"""Get talent system statistics"""
	var total_heroes = active_talent_effects.size()
	var talent_usage = {}
	
	# Count talent usage
	for hero in active_talent_effects:
		var hero_talents = active_talent_effects[hero]
		for talent_id in hero_talents:
			if not talent_usage.has(talent_id):
				talent_usage[talent_id] = 0
			talent_usage[talent_id] += 1
	
	return {
		"total_heroes_with_talents": total_heroes,
		"talent_usage": talent_usage,
		"pending_selections": talent_selection_queue.size()
	}

func _exit_tree() -> void:
	"""Clean up on exit"""
	active_talent_effects.clear()
	talent_selection_queue.clear()