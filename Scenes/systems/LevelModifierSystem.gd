class_name LevelModifierSystem
extends Node

## Level Modifier System
## Manages random level-wide effects that modify gameplay

signal modifiers_generated(modifiers: Array[Dictionary])
signal modifiers_applied(modifiers: Array[Dictionary])
signal modifiers_removed(modifiers: Array[Dictionary])
signal modifier_announcement(modifier: Dictionary)

# Current active modifiers
var active_modifiers: Array[Dictionary] = []
var current_wave: int = 0

# Modifier generation settings
var modifiers_per_wave: int = 2
var positive_modifier_weight: float = 0.4 # 40% chance for positive
var negative_modifier_weight: float = 0.35 # 35% chance for negative  
var neutral_modifier_weight: float = 0.25 # 25% chance for neutral

# Modifier application tracking
var applied_hero_effects: Dictionary = {} # hero -> [effect_ids]
var applied_tower_effects: Dictionary = {} # tower -> [effect_ids]

func _ready() -> void:
	# Connect to wave system
	setup_wave_connections()
	
	# Add to global systems
	add_to_group("level_systems")
	add_to_group("hero_systems")

func setup_wave_connections() -> void:
	"""Set up connections to wave management"""
	if Globals.has_signal("wave_started"):
		Globals.connect("wave_started", _on_wave_started)

func _on_wave_started(wave_count: int, enemy_count: int) -> void:
	"""Handle wave start and generate modifiers"""
	current_wave = wave_count
	
	# Generate modifiers every few waves
	if should_generate_modifiers(wave_count):
		generate_and_apply_wave_modifiers()

func should_generate_modifiers(wave: int) -> bool:
	"""Determine if modifiers should be generated for this wave"""
	# Generate modifiers every 3 waves starting from wave 2
	return wave >= 2 and (wave - 2) % 3 == 0

func generate_and_apply_wave_modifiers() -> void:
	"""Generate and apply random modifiers for current wave"""
	# Clear previous modifiers
	remove_all_modifiers()
	
	# Generate new modifiers
	var new_modifiers = generate_random_modifiers(modifiers_per_wave)
	
	if new_modifiers.is_empty():
		push_warning("No modifiers generated for wave " + str(current_wave))
		return
	
	# Apply modifiers
	apply_level_modifiers(new_modifiers)
	
	# Store as active
	active_modifiers = new_modifiers
	
	# Emit signals
	modifiers_generated.emit(new_modifiers)
	
	# Announce modifiers to UI
	for modifier in new_modifiers:
		modifier_announcement.emit(modifier)

func generate_random_modifiers(count: int = 2) -> Array[Dictionary]:
	"""Generate random level modifiers"""
	if not Data.level_modifiers:
		push_error("Level modifier data not available")
		return []
	
	var generated_modifiers: Array[Dictionary] = []
	var available_categories = ["positive", "negative", "neutral"]
	var used_modifier_ids: Array[String] = []
	
	for i in count:
		# Select category based on weights
		var category = select_weighted_category()
		var category_modifiers = Data.level_modifiers.get(category, [])
		
		if category_modifiers.is_empty():
			continue
		
		# Select random modifier from category (avoid duplicates)
		var available_modifiers = category_modifiers.filter(
			func(mod): return mod.id not in used_modifier_ids
		)
		
		if available_modifiers.is_empty():
			# If no unique modifiers, allow duplicates but with reduced effect
			available_modifiers = category_modifiers
		
		var selected_modifier = select_weighted_modifier(available_modifiers)
		if selected_modifier:
			generated_modifiers.append(selected_modifier.duplicate(true))
			used_modifier_ids.append(selected_modifier.id)
	
	return generated_modifiers

func select_weighted_category() -> String:
	"""Select modifier category based on weights"""
	var random_value = randf()
	var cumulative_weight = 0.0
	
	if random_value <= (cumulative_weight + positive_modifier_weight):
		return "positive"
	cumulative_weight += positive_modifier_weight
	
	if random_value <= (cumulative_weight + negative_modifier_weight):
		return "negative"
	
	return "neutral"

func select_weighted_modifier(modifiers: Array) -> Dictionary:
	"""Select modifier based on weight"""
	if modifiers.is_empty():
		return {}
	
	# Calculate total weight
	var total_weight = 0.0
	for modifier in modifiers:
		total_weight += modifier.get("weight", 1.0)
	
	# Select based on weight
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for modifier in modifiers:
		current_weight += modifier.get("weight", 1.0)
		if random_value <= current_weight:
			return modifier
	
	# Fallback to first modifier
	return modifiers[0]

func apply_level_modifiers(modifiers: Array[Dictionary]) -> void:
	"""Apply modifiers to game systems"""
	for modifier in modifiers:
		apply_single_modifier(modifier)
	
	modifiers_applied.emit(modifiers)

func apply_single_modifier(modifier: Dictionary) -> void:
	"""Apply individual modifier effects"""
	if not modifier.has("effects"):
		return
	
	var effects = modifier.effects
	
	for effect_key in effects:
		var effect_value = effects[effect_key]
		apply_modifier_effect(modifier.id, effect_key, effect_value)

func apply_modifier_effect(modifier_id: String, effect_key: String, effect_value) -> void:
	"""Apply specific modifier effect"""
	match effect_key:
		# Hero-specific effects
		"hero_damage_multiplier":
			apply_hero_damage_multiplier(effect_value)
		"respawn_time_multiplier":
			apply_hero_respawn_time_multiplier(effect_value)
		"charge_generation_multiplier":
			apply_hero_charge_multiplier(effect_value)
		"skill_cooldown_multiplier":
			apply_hero_skill_cooldown_multiplier(effect_value)
		"experience_multiplier":
			apply_hero_experience_multiplier(effect_value)
		"hero_hp_multiplier":
			apply_hero_hp_multiplier(effect_value)
		"skill_cost_multiplier":
			apply_hero_skill_cost_multiplier(effect_value)
		"attack_range_multiplier":
			apply_hero_range_multiplier(effect_value)
		"damage_multiplier":
			apply_hero_damage_multiplier(effect_value)
		"defense_multiplier":
			apply_hero_defense_multiplier(effect_value)
		"aura_radius_multiplier":
			apply_hero_aura_multiplier(effect_value)
		
		_:
			push_warning("Unknown modifier effect: " + effect_key)

func apply_hero_damage_multiplier(multiplier: float) -> void:
	"""Apply damage multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			var original_damage = hero.current_stats.get("damage", 0)
			hero.current_stats["damage"] = int(original_damage * multiplier)
			track_hero_effect(hero, "damage_multiplier_" + str(multiplier))

func apply_hero_respawn_time_multiplier(multiplier: float) -> void:
	"""Apply respawn time multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			hero.respawn_duration *= multiplier
			track_hero_effect(hero, "respawn_multiplier_" + str(multiplier))

func apply_hero_charge_multiplier(multiplier: float) -> void:
	"""Apply charge generation multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			hero.charge_generation_rate *= multiplier
			track_hero_effect(hero, "charge_multiplier_" + str(multiplier))

func apply_hero_skill_cooldown_multiplier(multiplier: float) -> void:
	"""Apply skill cooldown multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			for skill in hero.skills:
				skill.cooldown *= multiplier
			track_hero_effect(hero, "cooldown_multiplier_" + str(multiplier))

func apply_hero_experience_multiplier(multiplier: float) -> void:
	"""Apply experience gain multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			hero.set_meta("experience_multiplier", multiplier)
			track_hero_effect(hero, "experience_multiplier_" + str(multiplier))

func apply_hero_hp_multiplier(multiplier: float) -> void:
	"""Apply HP multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			var original_hp = hero.current_stats.get("max_hp", 100)
			hero.current_stats["max_hp"] = int(original_hp * multiplier)
			# Also adjust current HP proportionally
			if hero.health_bar:
				var hp_ratio = hero.health_bar.value / hero.health_bar.max_value
				hero.health_bar.max_value = hero.current_stats["max_hp"]
				hero.health_bar.value = hero.health_bar.max_value * hp_ratio
			track_hero_effect(hero, "hp_multiplier_" + str(multiplier))

func apply_hero_skill_cost_multiplier(multiplier: float) -> void:
	"""Apply skill cost multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			for skill in hero.skills:
				skill.charge_cost = int(skill.charge_cost * multiplier)
			track_hero_effect(hero, "skill_cost_multiplier_" + str(multiplier))

func apply_hero_range_multiplier(multiplier: float) -> void:
	"""Apply attack range multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			var original_range = hero.current_stats.get("attack_range", 0)
			hero.current_stats["attack_range"] = original_range * multiplier
			track_hero_effect(hero, "range_multiplier_" + str(multiplier))

func apply_hero_defense_multiplier(multiplier: float) -> void:
	"""Apply defense multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			var original_defense = hero.current_stats.get("defense", 0)
			hero.current_stats["defense"] = int(original_defense * multiplier)
			track_hero_effect(hero, "defense_multiplier_" + str(multiplier))

func apply_hero_aura_multiplier(multiplier: float) -> void:
	"""Apply aura radius multiplier to all heroes"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			for skill in hero.skills:
				if skill.skill_data.has("aura_radius"):
					skill.skill_data["aura_radius"] *= multiplier
			track_hero_effect(hero, "aura_multiplier_" + str(multiplier))

func apply_modifiers_to_heroes(heroes: Array[HeroBase]) -> void:
	"""Apply current modifiers to specific hero list"""
	for modifier in active_modifiers:
		for hero in heroes:
			if is_instance_valid(hero):
				apply_modifier_to_single_hero(modifier, hero)

func apply_modifier_to_single_hero(modifier: Dictionary, hero: HeroBase) -> void:
	"""Apply modifier to single hero"""
	if not modifier.has("effects") or not hero:
		return
	
	var effects = modifier.effects
	
	for effect_key in effects:
		var effect_value = effects[effect_key]
		apply_single_hero_effect(hero, effect_key, effect_value)

func apply_single_hero_effect(hero: HeroBase, effect_key: String, effect_value) -> void:
	"""Apply single effect to hero"""
	match effect_key:
		"hero_damage_multiplier", "damage_multiplier":
			var original = hero.current_stats.get("damage", 0)
			hero.current_stats["damage"] = int(original * effect_value)
		"hero_hp_multiplier":
			var original = hero.current_stats.get("max_hp", 100)
			hero.current_stats["max_hp"] = int(original * effect_value)
		"charge_generation_multiplier":
			hero.charge_generation_rate *= effect_value
		"respawn_time_multiplier":
			hero.respawn_duration *= effect_value
		"skill_cooldown_multiplier":
			for skill in hero.skills:
				skill.cooldown *= effect_value

func get_all_heroes() -> Array[HeroBase]:
	"""Get all deployed heroes"""
	var hero_manager = get_hero_manager()
	if hero_manager:
		return hero_manager.deployed_heroes
	
	# Fallback: find heroes in scene
	var heroes: Array[HeroBase] = []
	var tree = get_tree()
	if tree and tree.current_scene:
		var hero_nodes = tree.current_scene.get_tree().get_nodes_in_group("heroes")
		for node in hero_nodes:
			if node is HeroBase:
				heroes.append(node as HeroBase)
	
	return heroes

func get_hero_manager() -> HeroManager:
	"""Get hero manager instance"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	var manager = tree.current_scene.get_node_or_null("HeroManager") as HeroManager
	if not manager:
		# Try finding in main scene
		var main = tree.current_scene.get_node_or_null("Main")
		if main:
			manager = main.get_node_or_null("HeroManager") as HeroManager
	
	return manager

func track_hero_effect(hero: HeroBase, effect_id: String) -> void:
	"""Track applied effect for cleanup"""
	if not applied_hero_effects.has(hero):
		applied_hero_effects[hero] = []
	
	applied_hero_effects[hero].append(effect_id)

func remove_all_modifiers() -> void:
	"""Remove all active modifiers"""
	if active_modifiers.is_empty():
		return
	
	# Reset heroes to base stats
	reset_hero_stats()
	
	# Clear tracking
	applied_hero_effects.clear()
	applied_tower_effects.clear()
	
	modifiers_removed.emit(active_modifiers)
	active_modifiers.clear()

func reset_hero_stats() -> void:
	"""Reset all hero stats to base values"""
	var heroes = get_all_heroes()
	for hero in heroes:
		if is_instance_valid(hero):
			# Trigger hero data refresh to reset to base stats
			hero.setup_hero_data()
			# Reapply level bonuses
			hero.update_current_stats()

func get_active_modifiers() -> Array[Dictionary]:
	"""Get currently active modifiers"""
	return active_modifiers.duplicate(true)

func get_modifier_display_text(modifier: Dictionary) -> String:
	"""Generate display text for modifier"""
	if not modifier.has("name") or not modifier.has("description"):
		return "Unknown modifier"
	
	var text = modifier.name + "\n" + modifier.description
	
	# Add category indicator
	var category = get_modifier_category(modifier)
	match category:
		"positive":
			text = "[color=green]" + text + "[/color]"
		"negative":
			text = "[color=red]" + text + "[/color]"
		"neutral":
			text = "[color=yellow]" + text + "[/color]"
	
	return text

func get_modifier_category(modifier: Dictionary) -> String:
	"""Determine modifier category"""
	var modifier_id = modifier.get("id", "")
	
	# Check each category in Data
	for category in ["positive", "negative", "neutral"]:
		var category_modifiers = Data.level_modifiers.get(category, [])
		for mod in category_modifiers:
			if mod.id == modifier_id:
				return category
	
	return "unknown"

func get_modifier_summary() -> Dictionary:
	"""Get summary of modifier system state"""
	return {
		"current_wave": current_wave,
		"active_modifier_count": active_modifiers.size(),
		"active_modifiers": active_modifiers.duplicate(true),
		"affected_heroes": applied_hero_effects.size(),
		"next_modifier_wave": get_next_modifier_wave()
	}

func get_next_modifier_wave() -> int:
	"""Calculate when next modifiers will be generated"""
	if current_wave < 2:
		return 2
	
	# Find next wave that's 2 + (multiple of 3)
	var waves_since_start = current_wave - 2
	var cycles_passed = int(waves_since_start / 3)
	return 2 + ((cycles_passed + 1) * 3)

func force_generate_modifiers(modifier_ids: Array[String] = []) -> Array[Dictionary]:
	"""Force generate specific modifiers (for testing)"""
	var forced_modifiers: Array[Dictionary] = []
	
	if modifier_ids.is_empty():
		return generate_random_modifiers(2)
	
	# Find specific modifiers
	for modifier_id in modifier_ids:
		var modifier_data = find_modifier_by_id(modifier_id)
		if not modifier_data.is_empty():
			forced_modifiers.append(modifier_data)
	
	if not forced_modifiers.is_empty():
		apply_level_modifiers(forced_modifiers)
		active_modifiers = forced_modifiers
		modifiers_generated.emit(forced_modifiers)
	
	return forced_modifiers

func find_modifier_by_id(modifier_id: String) -> Dictionary:
	"""Find modifier data by ID"""
	for category in ["positive", "negative", "neutral"]:
		var category_modifiers = Data.level_modifiers.get(category, [])
		for modifier in category_modifiers:
			if modifier.id == modifier_id:
				return modifier.duplicate(true)
	
	return {}

func _exit_tree() -> void:
	"""Clean up on exit"""
	remove_all_modifiers()