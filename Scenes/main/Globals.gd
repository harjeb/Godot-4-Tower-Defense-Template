extends Node

## Game-wide signals using Godot 4.4 syntax
signal gold_changed(new_gold: int)
signal base_hp_changed(new_hp: int, max_hp: int)
signal wave_started(wave_count: int, enemy_count: int)
signal wave_cleared(wait_time: float)
signal enemy_destroyed(remain: int)

## Hero System Signals
signal hero_deployed(hero: HeroBase, position: Vector2)
signal hero_died(hero: HeroBase)
signal hero_respawned(hero: HeroBase) 
signal hero_skill_cast(hero: HeroBase, skill: HeroSkill)
signal level_modifiers_generated(modifiers: Array)
signal talent_selection_available(hero: HeroBase, level: int)
signal hero_selection_offered(available_heroes: Array[String])
signal hero_experience_gained(hero: HeroBase, amount: int)

## Game state variables with proper typing
var selected_map: String = ""
var main_node: Node2D
var turrets_node: Node2D
var projectiles_node: Node2D
var current_map: Node2D
var hud: Control

func restart_current_level() -> void:
	if not is_instance_valid(current_map):
		push_error("Cannot restart: current_map is invalid")
		return
	
	var scene_path = current_map.scene_file_path
	var current_level_scene = Data.load_resource_safe(scene_path, "PackedScene")
	if not current_level_scene:
		return
	
	current_map.queue_free()
	var new_map = current_level_scene.instantiate()
	if new_map.has_method("set_map_type"):
		new_map.set_map_type(selected_map)
	elif "map_type" in new_map:
		new_map.map_type = selected_map
	
	if is_instance_valid(main_node):
		main_node.add_child(new_map)
		current_map = new_map
	
	if is_instance_valid(hud) and hud.has_method("reset"):
		hud.reset()

## Hero System Integration Methods

func deploy_hero(hero_type: String, position: Vector2) -> HeroBase:
	"""Deploy a hero at specified position"""
	var hero_manager = get_hero_manager()
	if not hero_manager:
		push_error("HeroManager not available")
		return null
	
	var hero = hero_manager.deploy_hero(hero_type, position)
	if hero:
		hero_deployed.emit(hero, position)
	
	return hero

func get_hero_manager() -> HeroManager:
	"""Get reference to hero manager"""
	if not is_instance_valid(main_node):
		return null
	
	var manager = main_node.get_node_or_null("HeroManager") as HeroManager
	if not manager:
		# Try finding in main scene children
		for child in main_node.get_children():
			if child is HeroManager:
				return child
	
	return manager

func get_level_modifier_system() -> LevelModifierSystem:
	"""Get reference to level modifier system"""
	if not is_instance_valid(main_node):
		return null
	
	return main_node.get_node_or_null("LevelModifierSystem") as LevelModifierSystem

func get_hero_talent_system() -> HeroTalentSystem:
	"""Get reference to hero talent system"""
	if not is_instance_valid(main_node):
		return null
	
	return main_node.get_node_or_null("HeroTalentSystem") as HeroTalentSystem

func get_deployed_heroes() -> Array[HeroBase]:
	"""Get all currently deployed heroes"""
	var hero_manager = get_hero_manager()
	if hero_manager:
		return hero_manager.deployed_heroes
	
	return []

func get_living_heroes() -> Array[HeroBase]:
	"""Get all currently living heroes"""
	var heroes = get_deployed_heroes()
	var living_heroes: Array[HeroBase] = []
	
	for hero in heroes:
		if is_instance_valid(hero) and hero.is_alive:
			living_heroes.append(hero)
	
	return living_heroes

func request_hero_selection() -> void:
	"""Request hero selection from player"""
	var hero_manager = get_hero_manager()
	if hero_manager:
		hero_manager.offer_hero_selection()

func apply_wave_modifiers(modifiers: Array) -> void:
	"""Apply wave modifiers to heroes"""
	var level_modifier_system = get_level_modifier_system()
	if level_modifier_system:
		level_modifier_system.apply_level_modifiers(modifiers)

func notify_hero_experience_gained(hero: HeroBase, amount: int) -> void:
	"""Notify systems of hero experience gain"""
	hero_experience_gained.emit(hero, amount)

func get_hero_system_status() -> Dictionary:
	"""Get overview of hero system status"""
	var hero_manager = get_hero_manager()
	var talent_system = get_hero_talent_system()
	var modifier_system = get_level_modifier_system()
	
	return {
		"hero_manager_available": hero_manager != null,
		"talent_system_available": talent_system != null,
		"modifier_system_available": modifier_system != null,
		"deployed_heroes": get_deployed_heroes().size(),
		"living_heroes": get_living_heroes().size()
	}
