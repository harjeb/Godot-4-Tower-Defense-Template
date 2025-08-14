class_name HeroRangeIndicator
extends Node2D

## Hero Range Indicator System
## Provides visual feedback for hero deployment zones, skill ranges, and area effects

signal deployment_position_selected(position: Vector2)
signal deployment_cancelled()

# Visual components
var deployment_zone_circles: Array[Node2D] = []
var skill_range_circles: Array[Node2D] = []
var area_effect_circles: Array[Node2D] = []
var path_highlight_lines: Array[Line2D] = []

# Display state
var showing_deployment_zones: bool = false
var showing_skill_ranges: bool = false
var current_hero_type: String = ""
var current_hero_for_skills: Node

# Visual settings
var deployment_zone_color: Color = Color.GREEN
var deployment_zone_alpha: float = 0.3
var skill_range_color: Color = Color.BLUE  
var skill_effect_color: Color = Color.RED
var path_highlight_color: Color = Color.YELLOW
var circle_thickness: float = 3.0

# Input handling
var mouse_in_deployment_zone: bool = false
var nearest_deployment_position: Vector2

func _ready() -> void:
	# Set processing for input handling
	set_process_unhandled_input(true)
	
	# Initially hide all indicators
	hide_all_indicators()

func _draw() -> void:
	# Draw custom indicators if needed
	draw_custom_indicators()

func _unhandled_input(event: InputEvent) -> void:
	if not showing_deployment_zones:
		return
	
	if event is InputEventMouseMotion:
		update_mouse_position(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_deployment_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_deployment()

func show_deployment_zones(hero_type: String) -> void:
	"""Show valid deployment zones for hero type"""
	current_hero_type = hero_type
	showing_deployment_zones = true
	showing_skill_ranges = false
	
	# Clear existing indicators
	clear_all_indicators()
	
	# Get hero manager for deployment zones
	var hero_manager = get_hero_manager()
	if not hero_manager:
		push_error("HeroManager not available for deployment zones")
		return
	
	# Get deployment zones
	var deployment_zones = hero_manager.get_deployment_zones_data()
	
	# Create zone indicators
	create_deployment_zone_indicators(deployment_zones)
	
	# Highlight enemy paths
	highlight_enemy_paths()
	
	# Show instructions
	show_deployment_instructions()

func create_deployment_zone_indicators(zones: Array[Dictionary]) -> void:
	"""Create visual indicators for deployment zones"""
	for zone in zones:
		if zone.occupied:
			continue # Skip occupied zones
		
		var zone_circle = create_circle_indicator(
			zone.center,
			zone.radius,
			deployment_zone_color,
			deployment_zone_alpha
		)
		
		if zone_circle:
			deployment_zone_circles.append(zone_circle)
			add_child(zone_circle)

func highlight_enemy_paths() -> void:
	"""Highlight enemy paths for reference"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	var path_nodes = tree.current_scene.get_tree().get_nodes_in_group("enemy_path")
	
	# Create path highlight
	var path_line = Line2D.new()
	path_line.width = 8.0
	path_line.default_color = path_highlight_color
	path_line.default_color.a = 0.5
	
	# Add path points
	for path_node in path_nodes:
		if path_node.has_method("global_position"):
			path_line.add_point(path_node.global_position)
	
	if path_line.get_point_count() > 0:
		path_highlight_lines.append(path_line)
		add_child(path_line)

func show_skill_ranges(hero: Node) -> void:
	"""Show skill ranges for deployed hero"""
	if not hero or not is_instance_valid(hero):
		return
	
	current_hero_for_skills = hero
	showing_skill_ranges = true
	showing_deployment_zones = false
	
	# Clear existing indicators
	clear_all_indicators()
	
	# Show attack range
	create_attack_range_indicator(hero)
	
	# Show skill ranges
	for skill in hero.skills:
		create_skill_range_indicator(hero, skill)

func create_attack_range_indicator(hero: Node) -> void:
	"""Create attack range indicator for hero"""
	var attack_range = hero.current_stats.get("attack_range", 0.0)
	
	if attack_range > 0:
		var range_circle = create_circle_indicator(
			hero.global_position,
			attack_range,
			Color.WHITE,
			0.2
		)
		
		if range_circle:
			skill_range_circles.append(range_circle)
			add_child(range_circle)

func create_skill_range_indicator(hero: Node, skill: Node) -> void:
	"""Create range indicator for specific skill"""
	var skill_range = skill.get_area_of_effect()
	
	if skill_range > 0:
		var skill_color = skill.get_skill_type_color()
		
		var range_circle = create_circle_indicator(
			hero.global_position,
			skill_range,
			skill_color,
			0.3
		)
		
		if range_circle:
			skill_range_circles.append(range_circle)
			add_child(range_circle)
			
			# Add skill label
			create_skill_label(hero.global_position, skill_range, skill.skill_name, skill_color)

func highlight_affected_areas(skill: Node, position: Vector2) -> void:
	"""Highlight areas affected by skill cast"""
	if not skill:
		return
	
	# Clear previous area indicators
	clear_area_effect_indicators()
	
	var effect_radius = skill.get_area_of_effect()
	if effect_radius > 0:
		var effect_circle = create_circle_indicator(
			position,
			effect_radius,
			skill_effect_color,
			0.4
		)
		
		if effect_circle:
			area_effect_circles.append(effect_circle)
			add_child(effect_circle)
			
			# Add damage preview
			show_damage_preview(skill, position, effect_radius)

func show_damage_preview(skill: Node, center: Vector2, radius: float) -> void:
	"""Show damage preview for affected enemies"""
	var gem_effect_system = get_gem_effect_system()
	if not gem_effect_system:
		return
	
	var affected_enemies = gem_effect_system.get_enemies_in_area(center, radius)
	
	for enemy in affected_enemies:
		if is_instance_valid(enemy):
			create_damage_preview_label(enemy.global_position, skill, enemy)

func create_damage_preview_label(position: Vector2, skill: Node, target: Node) -> void:
	"""Create damage preview label"""
	var damage_label = Label.new()
	damage_label.position = position + Vector2(-20, -30)
	damage_label.text = "DMG: " + str(int(calculate_preview_damage(skill, target)))
	damage_label.add_theme_font_size_override("font_size", 12)
	damage_label.modulate = Color.YELLOW
	
	# Auto-remove after short time
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): damage_label.queue_free())
	damage_label.add_child(timer)
	timer.start()
	
	add_child(damage_label)

func calculate_preview_damage(skill: Node, target: Node) -> float:
	"""Calculate preview damage for skill on target"""
	if not current_hero_for_skills:
		return 0.0
	
	# Basic damage calculation
	var base_damage = skill.get_damage_value(current_hero_for_skills)
	
	# Apply hero's damage multipliers
	base_damage *= (1.0 + current_hero_for_skills.da_bonus + current_hero_for_skills.ta_bonus)
	
	return base_damage

func create_circle_indicator(center: Vector2, radius: float, color: Color, alpha: float) -> Node2D:
	"""Create a circle indicator at specified position"""
	var circle_node = Node2D.new()
	circle_node.position = center
	
	# Store circle data for drawing
	circle_node.set_meta("radius", radius)
	circle_node.set_meta("color", color)
	circle_node.set_meta("alpha", alpha)
	circle_node.set_meta("is_circle_indicator", true)
	
	return circle_node

func create_skill_label(center: Vector2, radius: float, skill_name: String, color: Color) -> void:
	"""Create skill name label"""
	var label = Label.new()
	label.position = center + Vector2(radius + 10, -10)
	label.text = skill_name
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = color
	
	skill_range_circles.append(label)
	add_child(label)

func draw_custom_indicators() -> void:
	"""Draw custom visual indicators"""
	# Draw circles for all circle indicators
	draw_all_circle_indicators()

func draw_all_circle_indicators() -> void:
	"""Draw all circle indicators"""
	var all_circles = deployment_zone_circles + skill_range_circles + area_effect_circles
	
	for circle_node in all_circles:
		if is_instance_valid(circle_node) and circle_node.has_meta("is_circle_indicator"):
			draw_circle_indicator(circle_node)

func draw_circle_indicator(circle_node: Node2D) -> void:
	"""Draw individual circle indicator"""
	if not circle_node:
		return
	
	var radius = circle_node.get_meta("radius", 50.0)
	var color = circle_node.get_meta("color", Color.WHITE)
	var alpha = circle_node.get_meta("alpha", 0.3)
	
	var center = circle_node.position
	
	# Draw filled circle (area)
	var fill_color = color
	fill_color.a = alpha
	draw_circle(center, radius, fill_color)
	
	# Draw circle outline
	var outline_color = color
	outline_color.a = min(1.0, alpha * 2)
	draw_arc(center, radius, 0, TAU, 64, outline_color, circle_thickness)

func update_mouse_position(mouse_pos: Vector2) -> void:
	"""Update mouse position for deployment preview"""
	if not showing_deployment_zones:
		return
	
	# Convert screen position to world position
	var world_pos = get_global_mouse_position()
	
	# Check if mouse is in valid deployment zone
	mouse_in_deployment_zone = false
	nearest_deployment_position = world_pos
	
	var hero_manager = get_hero_manager()
	if hero_manager:
		mouse_in_deployment_zone = hero_manager.can_deploy_hero_at_position(world_pos)
		
		if mouse_in_deployment_zone:
			# Snap to nearest valid position
			nearest_deployment_position = find_nearest_deployment_position(world_pos)
	
	queue_redraw()

func find_nearest_deployment_position(world_pos: Vector2) -> Vector2:
	"""Find nearest valid deployment position"""
	var hero_manager = get_hero_manager()
	if not hero_manager:
		return world_pos
	
	var valid_positions = hero_manager.get_valid_deployment_positions()
	var nearest_pos = world_pos
	var nearest_distance = INF
	
	for pos in valid_positions:
		var distance = world_pos.distance_to(pos)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_pos = pos
	
	return nearest_pos

func handle_deployment_click(mouse_pos: Vector2) -> void:
	"""Handle mouse click for hero deployment"""
	if not showing_deployment_zones or not mouse_in_deployment_zone:
		return
	
	deployment_position_selected.emit(nearest_deployment_position)
	hide_deployment_zones()

func cancel_deployment() -> void:
	"""Cancel hero deployment"""
	hide_deployment_zones()
	deployment_cancelled.emit()

func show_deployment_instructions() -> void:
	"""Show deployment instruction text"""
	var instruction_label = Label.new()
	instruction_label.text = "点击绿色区域部署英雄，右键取消"
	instruction_label.position = Vector2(10, 10)
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.modulate = Color.WHITE
	
	add_child(instruction_label)
	deployment_zone_circles.append(instruction_label) # For cleanup

func hide_deployment_zones() -> void:
	"""Hide deployment zone indicators"""
	showing_deployment_zones = false
	clear_deployment_zone_indicators()
	current_hero_type = ""

func hide_skill_ranges() -> void:
	"""Hide skill range indicators"""
	showing_skill_ranges = false
	clear_skill_range_indicators()
	current_hero_for_skills = null

func hide_all_indicators() -> void:
	"""Hide all range indicators"""
	hide_deployment_zones()
	hide_skill_ranges()
	clear_area_effect_indicators()

func clear_all_indicators() -> void:
	"""Clear all visual indicators"""
	clear_deployment_zone_indicators()
	clear_skill_range_indicators()
	clear_area_effect_indicators()
	clear_path_highlights()

func clear_deployment_zone_indicators() -> void:
	"""Clear deployment zone indicators"""
	for circle in deployment_zone_circles:
		if is_instance_valid(circle):
			circle.queue_free()
	deployment_zone_circles.clear()

func clear_skill_range_indicators() -> void:
	"""Clear skill range indicators"""
	for circle in skill_range_circles:
		if is_instance_valid(circle):
			circle.queue_free()
	skill_range_circles.clear()

func clear_area_effect_indicators() -> void:
	"""Clear area effect indicators"""
	for circle in area_effect_circles:
		if is_instance_valid(circle):
			circle.queue_free()
	area_effect_circles.clear()

func clear_path_highlights() -> void:
	"""Clear path highlight lines"""
	for line in path_highlight_lines:
		if is_instance_valid(line):
			line.queue_free()
	path_highlight_lines.clear()

func get_hero_manager() -> Node:
	"""Get reference to hero manager"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	var manager = tree.current_scene.get_node_or_null("HeroManager")
	if not manager:
		# Try finding in main scene
		var main = tree.current_scene.get_node_or_null("Main")
		if main:
			manager = main.get_node_or_null("HeroManager")
	
	return manager

func get_gem_effect_system() -> Node:
	"""Get reference to gem effect system"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	var system = tree.current_scene.get_node_or_null("GemEffectSystem")
	if not system:
		# Try finding in main scene
		var main = tree.current_scene.get_node_or_null("Main")
		if main:
			system = main.get_node_or_null("GemEffectSystem")
	
	return system

# External interface methods
func is_showing_deployment() -> bool:
	"""Check if showing deployment zones"""
	return showing_deployment_zones

func is_showing_skills() -> bool:
	"""Check if showing skill ranges"""
	return showing_skill_ranges

func update_hero_position(hero: Node) -> void:
	"""Update indicators for hero position change"""
	if current_hero_for_skills == hero:
		show_skill_ranges(hero)

func preview_skill_cast(hero: Node, skill: Node, target_position: Vector2) -> void:
	"""Preview skill cast effects"""
	current_hero_for_skills = hero
	highlight_affected_areas(skill, target_position)
	
	# Auto-hide preview after short time
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): clear_area_effect_indicators())
	add_child(timer)
	timer.start()

func set_visual_settings(settings: Dictionary) -> void:
	"""Update visual settings"""
	deployment_zone_color = settings.get("deployment_color", deployment_zone_color)
	deployment_zone_alpha = settings.get("deployment_alpha", deployment_zone_alpha)
	skill_range_color = settings.get("skill_color", skill_range_color)
	skill_effect_color = settings.get("effect_color", skill_effect_color)
	circle_thickness = settings.get("thickness", circle_thickness)
	
	queue_redraw()

func _exit_tree() -> void:
	"""Clean up on exit"""
	clear_all_indicators()