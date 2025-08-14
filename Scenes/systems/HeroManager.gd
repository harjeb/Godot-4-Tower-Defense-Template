class_name HeroManager
extends Node

## Hero Management System
## Handles hero deployment, lifecycle management, wave-based hero selection, and global hero coordination

signal hero_deployed(hero: Node, position: Vector2)
signal hero_died(hero: Node)
signal hero_respawned(hero: Node)
signal hero_leveled_up(hero: Node, new_level: int)
signal hero_selection_available(available_heroes: Array[String])
signal hero_selection_completed(selected_hero: String)
signal hero_selection_started(hero_type: String)
signal all_heroes_dead()
signal hero_experience_gained(hero: Node, amount: int)
signal talent_selection_requested(hero: Node, talents: Array[Dictionary])

# Hero management state
var deployed_heroes: Array[Node] = []
var hero_selection_queue: Array[String] = [] # Heroes available for selection
var max_deployed_heroes: int = 5
var next_selection_wave: int = 3 # Wave when next hero selection is available

# Hero selection system (5-choose-1)
var selection_cooldown_waves: int = 5 # Waves between selections
var last_selection_wave: int = 0
var pending_hero_selection: bool = false
var available_hero_pool: Array[String] = []

# Wave integration
var current_wave: int = 0
var wave_manager: Node

# Hero experience and progression
var global_experience_multiplier: float = 1.0
var experience_sharing_radius: float = 400.0
var enable_experience_sharing: bool = true

# Deployment system
var valid_deployment_positions: Array[Vector2] = []
var deployment_zones: Array[Dictionary] = []
var deployment_range_from_path: float = 50.0

# Performance optimization
var heroes_update_timer: float = 0.0
var heroes_update_interval: float = 0.1 # Update heroes every 100ms instead of every frame

func _ready() -> void:
	# Set up system connections
	setup_system_connections()
	
	# Initialize hero pool
	setup_hero_pool()
	
	# Initialize deployment zones
	setup_deployment_zones()
	
	# Connect to wave system
	connect_to_wave_system()
	
	# Add to global systems
	add_to_group("hero_systems")

func _process(delta: float) -> void:
	# Update heroes periodically for performance
	heroes_update_timer += delta
	if heroes_update_timer >= heroes_update_interval:
		update_heroes_system()
		heroes_update_timer = 0.0
	
	# Check for automatic hero selections
	check_wave_based_hero_selection()

func setup_system_connections() -> void:
	"""Set up connections to global signals"""
	if Globals.has_signal("wave_started"):
		Globals.connect("wave_started", _on_wave_started)
	
	if Globals.has_signal("enemy_destroyed"):
		Globals.connect("enemy_destroyed", _on_enemy_destroyed)

func setup_hero_pool() -> void:
	"""Initialize available hero pool"""
	if not Data.heroes:
		push_error("Hero data not available in Data.gd")
		return
	
	available_hero_pool = Data.heroes.keys()
	
	# Ensure we have at least 5 heroes for selection system
	if available_hero_pool.size() < 5:
		push_warning("Less than 5 heroes available, selection system may not work properly")

func setup_deployment_zones() -> void:
	"""Initialize valid deployment zones along enemy paths"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	# Find enemy path nodes
	var path_nodes = tree.current_scene.get_tree().get_nodes_in_group("enemy_path")
	deployment_zones.clear()
	valid_deployment_positions.clear()
	
	for path_node in path_nodes:
		var zone = {
			"center": path_node.global_position,
			"radius": deployment_range_from_path,
			"occupied": false,
			"hero": null
		}
		deployment_zones.append(zone)
		
		# Add specific deployment positions around path
		var positions = generate_deployment_positions_around_point(path_node.global_position)
		valid_deployment_positions.append_array(positions)

func generate_deployment_positions_around_point(center: Vector2) -> Array[Vector2]:
	"""Generate valid deployment positions around a point"""
	var positions: Array[Vector2] = []
	var angles = [0, 45, 90, 135, 180, 225, 270, 315] # 8 directions
	var distance = deployment_range_from_path
	
	for angle in angles:
		var rad = deg_to_rad(angle)
		var offset = Vector2(cos(rad), sin(rad)) * distance
		positions.append(center + offset)
	
	return positions

func connect_to_wave_system() -> void:
	"""Connect to wave management system"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	wave_manager = tree.current_scene.get_node_or_null("WaveManager")
	if not wave_manager:
		# Try finding in main scene
		var main = tree.current_scene.get_node_or_null("Main")
		if main:
			wave_manager = main.get_node_or_null("WaveManager")

func update_heroes_system() -> void:
	"""Update all hero-related systems"""
	update_hero_states()
	update_deployment_zones()
	check_hero_deaths()
	process_experience_sharing()

func update_hero_states() -> void:
	"""Update states of all deployed heroes"""
	for i in range(deployed_heroes.size() - 1, -1, -1):
		var hero = deployed_heroes[i]
		
		if not is_instance_valid(hero):
			deployed_heroes.remove_at(i)
			continue
		
		# Update hero-specific logic if needed
		update_individual_hero(hero)

func update_individual_hero(hero: Node) -> void:
	"""Update individual hero state"""
	if not hero:
		return
	
	# Check if hero needs talent selection
	if hero.pending_talent_selection and hero.available_talents.size() > 0:
		request_talent_selection(hero)

func update_deployment_zones() -> void:
	"""Update deployment zone occupancy"""
	for zone in deployment_zones:
		if zone.occupied and zone.hero:
			if not is_instance_valid(zone.hero) or not zone.hero.is_alive:
				zone.occupied = false
				zone.hero = null

func check_hero_deaths() -> void:
	"""Check for hero deaths and handle respawn logic"""
	var all_dead = true
	
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.is_alive:
			all_dead = false
			break
	
	if all_dead and deployed_heroes.size() > 0:
		all_heroes_dead.emit()

func process_experience_sharing() -> void:
	"""Handle experience sharing between nearby heroes"""
	if not enable_experience_sharing:
		return
	
	# This would be implemented based on specific game rules
	# For now, experience is handled individually in hero_destroyed events

func check_wave_based_hero_selection() -> void:
	"""Check if hero selection should be offered based on wave"""
	if pending_hero_selection:
		return
	
	if current_wave >= next_selection_wave and current_wave - last_selection_wave >= selection_cooldown_waves:
		offer_hero_selection()

func offer_hero_selection() -> void:
	"""Offer hero selection to player"""
	if available_hero_pool.size() < 5:
		push_warning("Not enough heroes for selection")
		return
	
	# Select 5 random heroes from pool
	var selection_options = get_random_heroes_for_selection(5)
	hero_selection_queue = selection_options
	pending_hero_selection = true
	
	hero_selection_available.emit(selection_options)

func get_random_heroes_for_selection(count: int) -> Array[String]:
	"""Get random heroes for selection"""
	var available = available_hero_pool.duplicate()
	var selected: Array[String] = []
	
	# Remove already deployed hero types to avoid duplicates
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.hero_type in available:
			available.erase(hero.hero_type)
	
	# Randomly select heroes
	for i in count:
		if available.is_empty():
			break
		
		var random_index = randi() % available.size()
		var hero_type = available[random_index]
		selected.append(hero_type)
		available.remove_at(random_index)
	
	return selected

func select_hero(hero_type: String) -> void:
	"""Handle hero selection from UI"""
	if not pending_hero_selection:
		push_warning("No pending hero selection")
		return
	
	if not hero_type in hero_selection_queue:
		push_error("Invalid hero selection: " + hero_type)
		return
	
	# Complete selection
	pending_hero_selection = false
	last_selection_wave = current_wave
	next_selection_wave = current_wave + selection_cooldown_waves
	hero_selection_queue.clear()
	
	hero_selection_completed.emit(hero_type)
	
	# Show deployment interface
	show_hero_deployment_interface(hero_type)

func show_hero_deployment_interface(hero_type: String) -> void:
	"""Show deployment interface for selected hero"""
	# Emit signal that hero selection started
	hero_selection_started.emit(hero_type)
	
	# Get hero range indicator system
	var range_indicator = get_hero_range_indicator()
	if range_indicator:
		range_indicator.show_deployment_zones(hero_type)
	
	# Enable deployment mode
	set_deployment_mode(true, hero_type)

func get_hero_range_indicator() -> Node:
	"""Get hero range indicator system"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("HeroRangeIndicator")

func set_deployment_mode(enabled: bool, hero_type: String = "") -> void:
	"""Enable or disable hero deployment mode"""
	if enabled:
		# Store hero type for deployment
		set_meta("pending_deployment_hero", hero_type)
		set_meta("deployment_mode_active", true)
	else:
		remove_meta("pending_deployment_hero")
		remove_meta("deployment_mode_active")

func is_deployment_mode_active() -> bool:
	"""Check if deployment mode is active"""
	return get_meta("deployment_mode_active", false)

func get_pending_deployment_hero() -> String:
	"""Get hero type pending deployment"""
	return get_meta("pending_deployment_hero", "")

func deploy_hero(hero_type: String, position: Vector2) -> Node:
	"""Deploy a hero at specified position"""
	# Validate deployment
	if not can_deploy_hero_at_position(position):
		push_warning("Cannot deploy hero at position: " + str(position))
		return null
	
	if deployed_heroes.size() >= max_deployed_heroes:
		push_warning("Maximum heroes deployed")
		return null
	
	if not Data.heroes.has(hero_type):
		push_error("Hero type not found: " + hero_type)
		return null
	
	# Create hero instance
	var hero = create_hero_instance(hero_type)
	if not hero:
		return null
	
	# Set position and deploy
	hero.global_position = position
	
	# Add to scene
	var tree = get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(hero)
	
	# Register hero
	deployed_heroes.append(hero)
	
	# Connect hero signals
	connect_hero_signals(hero)
	
	# Mark deployment zone as occupied
	mark_deployment_zone_occupied(position, hero)
	
	# Disable deployment mode
	set_deployment_mode(false)
	
	hero_deployed.emit(hero, position)
	return hero

func create_hero_instance(hero_type: String) -> Node:
	"""Create hero instance from hero type"""
	var hero_data = Data.heroes[hero_type]
	var scene_path = hero_data.get("scene", "")
	
	if scene_path.is_empty():
		# Use base hero scene
		scene_path = "res://Scenes/heroes/HeroBase.tscn"
	
	var hero_scene = Data.load_resource_safe(scene_path, "PackedScene")
	if not hero_scene:
		push_error("Could not load hero scene: " + scene_path)
		return null
	
	var hero = hero_scene.instantiate()
	if not hero:
		push_error("Hero scene does not contain valid hero")
		return null
	
	# Configure hero
	hero.hero_type = hero_type
	hero.name = hero_type + "_" + str(deployed_heroes.size() + 1)
	
	return hero

func connect_hero_signals(hero: Node) -> void:
	"""Connect hero signals to manager"""
	if hero.has_signal("hero_died"):
		hero.connect("hero_died", _on_hero_died)
	
	if hero.has_signal("hero_respawned"):
		hero.connect("hero_respawned", _on_hero_respawned)
	
	if hero.has_signal("hero_leveled_up"):
		hero.connect("hero_leveled_up", _on_hero_leveled_up)
	
	if hero.has_signal("experience_gained"):
		hero.connect("experience_gained", _on_hero_experience_gained)

func can_deploy_hero_at_position(position: Vector2) -> bool:
	"""Check if hero can be deployed at position"""
	# Check if position is near enemy path
	var near_path = false
	for zone in deployment_zones:
		if position.distance_to(zone.center) <= zone.radius:
			near_path = true
			break
	
	if not near_path:
		return false
	
	# Check if position is not occupied by another hero
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.global_position.distance_to(position) < 60.0:
			return false
	
	return true

func mark_deployment_zone_occupied(position: Vector2, hero: Node) -> void:
	"""Mark closest deployment zone as occupied"""
	var closest_zone = null
	var closest_distance = INF
	
	for zone in deployment_zones:
		var distance = position.distance_to(zone.center)
		if distance < closest_distance and distance <= zone.radius:
			closest_distance = distance
			closest_zone = zone
	
	if closest_zone:
		closest_zone.occupied = true
		closest_zone.hero = hero

func get_deployed_hero_count() -> int:
	"""Get number of deployed heroes"""
	var count = 0
	for hero in deployed_heroes:
		if is_instance_valid(hero):
			count += 1
	return count

func get_living_hero_count() -> int:
	"""Get number of living heroes"""
	var count = 0
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.is_alive:
			count += 1
	return count

func get_hero_by_name(hero_name: String) -> Node:
	"""Get deployed hero by name"""
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.name == hero_name:
			return hero
	return null

func get_heroes_by_type(hero_type: String) -> Array[Node]:
	"""Get all deployed heroes of specific type"""
	var heroes: Array[Node] = []
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.hero_type == hero_type:
			heroes.append(hero)
	return heroes

func get_nearest_hero_to_position(position: Vector2) -> Node:
	"""Get nearest hero to a position"""
	var nearest_hero: Node = null
	var nearest_distance = INF
	
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.is_alive:
			var distance = hero.global_position.distance_to(position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_hero = hero
	
	return nearest_hero

func remove_hero(hero: Node) -> void:
	"""Remove hero from deployment"""
	if not hero:
		return
	
	# Remove from deployed list
	deployed_heroes.erase(hero)
	
	# Free deployment zone
	for zone in deployment_zones:
		if zone.hero == hero:
			zone.occupied = false
			zone.hero = null
			break
	
	# Clean up hero
	if is_instance_valid(hero):
		hero.queue_free()

func request_talent_selection(hero: Node) -> void:
	"""Request talent selection for hero"""
	if not hero or hero.available_talents.is_empty():
		return
	
	# Emit signal for talent selection UI
	talent_selection_requested.emit(hero, hero.available_talents)
	
	# Get talent selection UI (backup method)
	var talent_ui = get_hero_talent_ui()
	if talent_ui:
		talent_ui.show_talent_selection(hero, hero.available_talents)

func get_hero_talent_ui() -> Control:
	"""Get hero talent selection UI"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("HeroTalentSelection") as Control

func get_deployment_zones_data() -> Array[Dictionary]:
	"""Get deployment zones for UI display"""
	return deployment_zones.duplicate()

func get_valid_deployment_positions() -> Array[Vector2]:
	"""Get valid deployment positions"""
	return valid_deployment_positions.duplicate()

# Signal handlers
func _on_wave_started(wave_count: int, enemy_count: int) -> void:
	"""Handle wave start"""
	current_wave = wave_count
	
	# Apply wave modifiers to heroes
	apply_wave_modifiers_to_heroes()

func _on_enemy_destroyed(remain: int) -> void:
	"""Handle enemy destruction for experience gain"""
	# Give experience to nearby heroes
	var experience_amount = 10 # Base experience per kill
	
	for hero in deployed_heroes:
		if is_instance_valid(hero) and hero.is_alive:
			# Give experience based on proximity or other criteria
			hero.gain_experience(experience_amount)

func _on_hero_died(hero: Node) -> void:
	"""Handle hero death"""
	hero_died.emit(hero)

func _on_hero_respawned(hero: Node) -> void:
	"""Handle hero respawn"""
	hero_respawned.emit(hero)

func _on_hero_leveled_up(hero: Node, new_level: int) -> void:
	"""Handle hero level up"""
	hero_leveled_up.emit(hero, new_level)

func _on_hero_experience_gained(hero: Node, amount: int, new_total: int) -> void:
	"""Handle hero experience gain"""
	hero_experience_gained.emit(hero, amount)

func apply_wave_modifiers_to_heroes() -> void:
	"""Apply current wave modifiers to heroes"""
	var level_modifier_system = get_level_modifier_system()
	if level_modifier_system:
		level_modifier_system.apply_modifiers_to_heroes(deployed_heroes)

func get_level_modifier_system() -> Node:
	"""Get level modifier system"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("LevelModifierSystem")

# Save/Load system
func get_save_data() -> Dictionary:
	"""Get save data for heroes"""
	var save_data = {
		"current_wave": current_wave,
		"last_selection_wave": last_selection_wave,
		"next_selection_wave": next_selection_wave,
		"deployed_heroes": []
	}
	
	for hero in deployed_heroes:
		if is_instance_valid(hero):
			var hero_data = {
				"hero_type": hero.hero_type,
				"position": hero.global_position,
				"level": hero.current_level,
				"experience": hero.experience_points,
				"talents": hero.talent_selections
			}
			save_data.deployed_heroes.append(hero_data)
	
	return save_data

func load_save_data(save_data: Dictionary) -> void:
	"""Load save data for heroes"""
	current_wave = save_data.get("current_wave", 0)
	last_selection_wave = save_data.get("last_selection_wave", 0)
	next_selection_wave = save_data.get("next_selection_wave", 3)
	
	var hero_data_list = save_data.get("deployed_heroes", [])
	for hero_data in hero_data_list:
		var hero = deploy_hero(hero_data.hero_type, hero_data.position)
		if hero:
			hero.current_level = hero_data.get("level", 1)
			hero.experience_points = hero_data.get("experience", 0)
			hero.talent_selections = hero_data.get("talents", {})

func _exit_tree() -> void:
	"""Clean up on exit"""
	# Clean up deployed heroes
	for hero in deployed_heroes:
		if is_instance_valid(hero):
			hero.queue_free()
	
	deployed_heroes.clear()