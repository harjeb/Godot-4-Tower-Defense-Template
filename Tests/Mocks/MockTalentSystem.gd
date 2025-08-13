extends Node
class_name MockTalentSystem

## Mock Talent System for testing
## Simulates talent system functionality

signal talent_selected(hero: HeroBase, talent: Dictionary)
signal talent_applied(hero: HeroBase, talent: Dictionary)
signal level_up(hero: HeroBase, new_level: int)

var active_talents: Dictionary = {}  # hero_id -> [talents]
var talent_effects: Dictionary = {}  # talent_id -> effect_data

func _ready():
	# Initialize mock talent effects
	initialize_talent_effects()

func initialize_talent_effects():
	"""Initialize mock talent effect data"""
	talent_effects = {
		"enhanced_strikes": {
			"skill": "shadow_strike",
			"effect": "attack_count",
			"value": 2,
			"operation": "add"
		},
		"rapid_charge": {
			"stat": "charge_generation",
			"value": 1.5,
			"operation": "multiply"
		},
		"flame_mastery": {
			"skill": "flame_armor",
			"effect": "aura_damage",
			"value": 2.0,
			"operation": "multiply"
		},
		"defensive_stance": {
			"stat": "defense",
			"value": 10,
			"operation": "add"
		}
	}

func apply_talent(hero: HeroBase, talent: Dictionary) -> bool:
	"""Apply a talent to a hero"""
	if not talent.has("id"):
		return false
	
	var hero_id = hero.get_instance_id()
	if not active_talents.has(hero_id):
		active_talents[hero_id] = []
	
	# Check if talent already applied
	for existing_talent in active_talents[hero_id]:
		if existing_talent.id == talent.id:
			return false
	
	# Apply talent effects
	if talent_effects.has(talent.id):
		var effect = talent_effects[talent.id]
		apply_talent_effect_to_hero(hero, effect)
	
	active_talents[hero_id].append(talent)
	talent_applied.emit(hero, talent)
	
	return true

func apply_talent_effect_to_hero(hero: HeroBase, effect: Dictionary):
	"""Apply specific talent effect to hero"""
	match effect.get("stat"):
		"charge_generation":
			if effect.operation == "multiply":
				hero.charge_generation *= effect.value
			elif effect.operation == "add":
				hero.charge_generation += effect.value
	
	match effect.get("effect"):
		"attack_count":
			# This would modify skill data
			pass
		"aura_damage":
			# This would modify skill aura damage
			pass

func remove_talent(hero: HeroBase, talent_id: String) -> bool:
	"""Remove a talent from a hero"""
	var hero_id = hero.get_instance_id()
	if not active_talents.has(hero_id):
		return false
	
	for i in range(active_talents[hero_id].size()):
		if active_talents[hero_id][i].id == talent_id:
			active_talents[hero_id].remove_at(i)
			return true
	
	return false

func get_active_talents(hero: HeroBase) -> Array:
	"""Get active talents for a hero"""
	var hero_id = hero.get_instance_id()
	return active_talents.get(hero_id, [])

func has_talent(hero: HeroBase, talent_id: String) -> bool:
	"""Check if hero has specific talent"""
	var talents = get_active_talents(hero)
	for talent in talents:
		if talent.id == talent_id:
			return true
	return false

func get_talent_effect(hero: HeroBase, talent_id: String) -> Dictionary:
	"""Get effect data for specific talent"""
	if has_talent(hero, talent_id) and talent_effects.has(talent_id):
		return talent_effects[talent_id]
	return {}

func clear_talents(hero: HeroBase):
	"""Clear all talents from a hero"""
	var hero_id = hero.get_instance_id()
	if active_talents.has(hero_id):
		active_talents[hero_id].clear()

func simulate_level_up(hero: HeroBase, new_level: int):
	"""Simulate hero level up"""
	level_up.emit(hero, new_level)