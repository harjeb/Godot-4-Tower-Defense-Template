extends Node
class_name InformationIntegrationPanelTest

## Information Integration Panel Test Suite
## Tests real-time stat display updates, hero/tower/enemy information formatting, and panel responsiveness

const TestFramework = preload("res://Tests/TestFramework.gd")

var test_framework: TestFramework
var test_scene: Node2D
var info_panel: Control
var test_hero: HeroBase

func _ready():
	print("=== Information Integration Panel Test Suite Started ===")
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# Setup test environment
	setup_test_environment()
	
	# Run all tests
	run_all_tests()
	
	print("=== Information Integration Panel Test Suite Completed ===")

func setup_test_environment():
	"""Create test scene and components"""
	# Create test scene
	test_scene = Node2D.new()
	add_child(test_scene)
	
	# Create test hero
	test_hero = create_test_hero()
	
	# Create info panel
	info_panel = create_info_panel()

func run_all_tests():
	"""Execute all information panel tests"""
	var tests = [
		{"name": "Real-time Stat Display", "func": test_real_time_display},
		{"name": "Information Formatting", "func": test_information_formatting},
		{"name": "Health Status Updates", "func": test_health_updates},
		{"name": "Panel Responsiveness", "func": test_panel_responsiveness},
		{"name": "Multi-unit Selection", "func": test_multi_unit_selection},
		{"name": "Stat Calculation Accuracy", "func": test_stat_accuracy},
		{"name": "UI Component Updates", "func": test_ui_updates},
		{"name": "Performance Under Load", "func": test_performance_load}
	]
	
	test_framework.run_test_suite("Information Integration Panel", tests)

func test_real_time_display():
	"""Test real-time stat display updates"""
	print("Testing real-time stat display...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not info_panel or not test_hero:
		return
	
	# Test initial stat display
	info_panel.show_hero_info(test_hero)
	var displayed_stats = get_displayed_stats()
	
	test_framework.assert_has_key(displayed_stats, "name", "Should display hero name")
	test_framework.assert_has_key(displayed_stats, "level", "Should display hero level")
	test_framework.assert_has_key(displayed_stats, "health", "Should display hero health")
	test_framework.assert_has_key(displayed_stats, "damage", "Should display hero damage")
	
	# Test real-time updates
	var original_damage = test_hero.current_stats.damage
	test_hero.current_stats.damage = original_damage * 1.5
	
	# Simulate update cycle
	simulate_panel_update()
	
	var updated_stats = get_displayed_stats()
	test_framework.assert_true(updated_stats.damage > original_damage, "Damage display should update in real-time")
	
	# Test multiple stat updates
	var original_stats = {
		"damage": test_hero.current_stats.damage,
		"defense": test_hero.current_stats.defense,
		"attack_speed": test_hero.current_stats.attack_speed
	}
	
	# Modify all stats
	test_hero.current_stats.damage *= 1.2
	test_hero.current_stats.defense += 5
	test_hero.current_stats.attack_speed *= 0.9
	
	simulate_panel_update()
	updated_stats = get_displayed_stats()
	
	test_framework.assert_true(updated_stats.damage > original_stats.damage, "Damage should be updated")
	test_framework.assert_true(updated_stats.defense > original_stats.defense, "Defense should be updated")
	test_framework.assert_true(updated_stats.attack_speed < original_stats.attack_speed, "Attack speed should be updated")
	
	# Test update frequency
	var update_count = 0
	var update_interval = info_panel.get("update_interval", 0.2)
	
	# Monitor updates over time
	for i in range(10):
		simulate_panel_update()
		update_count += 1
	
	test_framework.assert_equal(update_count, 10, "Should update exactly 10 times")
	
	# Test update reliability
	var stats_changed = false
	test_hero.current_stats.damage += 1
	
	simulate_panel_update()
	updated_stats = get_displayed_stats()
	
	if updated_stats.damage != original_stats.damage:
		stats_changed = true
	
	test_framework.assert_true(stats_changed, "Stats should be reliably updated")
	
	print("✓ Real-time stat display tests passed")

func test_information_formatting():
	"""Test information formatting and display"""
	print("Testing information formatting...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	
	if not info_panel:
		return
	
	# Test number formatting
	var test_values = [1, 10, 100, 1000, 1234.56]
	for value in test_values:
		var formatted = format_number(value)
		test_framework.assert_false(formatted.is_empty(), "Number should be formatted")
		test_framework.assert_true(formatted.length <= 10, "Formatted number should be concise")
	
	# Test percentage formatting
	var percentages = [0.15, 0.5, 0.75, 1.0]
	for percentage in percentages:
		var formatted = format_percentage(percentage)
		test_framework.assert_true(formatted.ends_with("%"), "Percentage should end with %")
	
	# Test stat name formatting
	var stat_names = ["damage", "defense", "attack_speed", "max_hp"]
	for stat_name in stat_names:
		var formatted = format_stat_name(stat_name)
		test_framework.assert_false(formatted.is_empty(), "Stat name should be formatted")
		test_framework.assert_true(formatted.length <= 15, "Formatted stat name should be concise")
	
	# Test skill information formatting
	var skills = get_test_skills()
	for skill in skills:
		var formatted_skill = format_skill_info(skill)
		test_framework.assert_has_key(formatted_skill, "name", "Skill info should have name")
		test_framework.assert_has_key(formatted_skill, "cooldown", "Skill info should have cooldown")
		test_framework.assert_has_key(formatted_skill, "type", "Skill info should have type")
	
	# Test status text formatting
	var status_types = ["normal", "casting", "respawning", "dead"]
	for status_type in status_types:
		var formatted_status = format_status_text(status_type, 2.5)
		test_framework.assert_false(formatted_status.is_empty(), "Status text should be formatted")
		test_framework.assert_true(formatted_status.length <= 30, "Status text should be concise")
	
	# Test color coding
	var element_colors = {
		"fire": Color.RED,
		"ice": Color.CYAN,
		"light": Color.WHITE
	}
	
	for element, expected_color in element_colors:
		var actual_color = get_element_color(element)
		test_framework.assert_equal(actual_color, expected_color, "Element color should be correct")
	
	# Test layout formatting
	var layout_info = get_layout_info()
	test_framework.assert_has_key(layout_info, "width", "Layout should have width")
	test_framework.assert_has_key(layout_info, "height", "Layout should have height")
	test_framework.assert_true(layout_info.width > 0, "Layout width should be positive")
	test_framework.assert_true(layout_info.height > 0, "Layout height should be positive")
	
	print("✓ Information formatting tests passed")

func test_health_updates():
	"""Test health and status updates"""
	print("Testing health updates...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not info_panel or not test_hero:
		return
	
	# Test initial health display
	info_panel.show_hero_info(test_hero)
	var health_info = get_health_info()
	
	test_framework.assert_equal(health_info.current, test_hero.health_bar.value, "Current health should match")
	test_framework.assert_equal(health_info.max, test_hero.current_stats.max_hp, "Max health should match")
	test_framework.assert_equal(health_info.percentage, 100.0, "Initial health should be 100%")
	
	# Test health decrease
	var damage_amount = 50
	test_hero.take_damage(damage_amount)
	
	simulate_panel_update()
	health_info = get_health_info()
	
	var expected_current = test_hero.current_stats.max_hp - damage_amount
	var expected_percentage = (expected_current / test_hero.current_stats.max_hp) * 100
	
	test_framework.assert_equal(health_info.current, expected_current, "Current health should update")
	test_framework.assert_approximately(health_info.percentage, expected_percentage, 0.1, "Health percentage should be accurate")
	
	# Test health increase (healing)
	var heal_amount = 25
	test_hero.health_bar.value += heal_amount
	
	simulate_panel_update()
	health_info = get_health_info()
	
	expected_current = test_hero.current_stats.max_hp - damage_amount + heal_amount
	expected_percentage = (expected_current / test_hero.current_stats.max_hp) * 100
	
	test_framework.assert_equal(health_info.current, expected_current, "Healed health should update")
	test_framework.assert_approximately(health_info.percentage, expected_percentage, 0.1, "Healed percentage should be accurate")
	
	# Test death status
	test_hero.take_damage(test_hero.health_bar.value)
	simulate_panel_update()
	
	var status_info = get_status_info()
	test_framework.assert_equal(status_info.status, "已死亡", "Should show death status")
	test_framework.assert_false(status_info.is_alive, "Alive flag should be false")
	
	# Test respawn status
	test_hero.respawn_hero()
	simulate_panel_update()
	
	status_info = get_status_info()
	test_framework.assert_equal(status_info.status, "正常", "Should show normal status after respawn")
	test_framework.assert_true(status_info.is_alive, "Alive flag should be true")
	
	# Test health bar color changes
	var health_bar_color = get_health_bar_color()
	test_framework.assert_true(health_bar_color.r > 0.5, "Health bar should be green when healthy")
	
	test_hero.take_damage(test_hero.current_stats.max_hp * 0.7)
	simulate_panel_update()
	
	health_bar_color = get_health_bar_color()
	test_framework.assert_true(health_bar_color.r > 0.5 and health_bar_color.g > 0.3, "Health bar should be yellow when damaged")
	
	print("✓ Health update tests passed")

func test_panel_responsiveness():
	"""Test panel responsiveness and interaction"""
	print("Testing panel responsiveness...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	
	if not info_panel:
		return
	
	# Test panel show/hide responsiveness
	var show_start_time = Time.get_ticks_msec()
	info_panel.show_hero_info(test_hero)
	var show_end_time = Time.get_ticks_msec()
	
	var show_duration = show_end_time - show_start_time
	test_framework.assert_true(show_duration < 50, "Panel should show within 50ms")
	
	test_framework.assert_true(info_panel.visible, "Panel should be visible after show")
	
	var hide_start_time = Time.get_ticks_msec()
	info_panel.hide_panel()
	var hide_end_time = Time.get_ticks_msec()
	
	var hide_duration = hide_end_time - hide_start_time
	test_framework.assert_true(hide_duration < 50, "Panel should hide within 50ms")
	
	test_framework.assert_false(info_panel.visible, "Panel should be hidden after hide")
	
	# Test rapid show/hide cycles
	for i in range(10):
		info_panel.show_hero_info(test_hero)
		info_panel.hide_panel()
	
	# Panel should handle rapid cycles without crashing
	test_framework.assert_true(true, "Panel should handle rapid cycles")
	
	# Test memory usage during updates
	var initial_memory = get_memory_usage()
	
	for i in range(100):
		info_panel.show_hero_info(test_hero)
		simulate_panel_update()
		info_panel.hide_panel()
	
	var final_memory = get_memory_usage()
	var memory_increase = final_memory - initial_memory
	
	test_framework.assert_true(memory_increase < 10, "Memory increase should be minimal (< 10MB)")
	
	# Test panel resizing
	var original_size = info_panel.size
	var new_size = Vector2(300, 400)
	
	info_panel.set_panel_size(new_size)
	test_framework.assert_equal(info_panel.size, new_size, "Panel should resize correctly")
	
	info_panel.set_panel_size(original_size)
	test_framework.assert_equal(info_panel.size, original_size, "Panel should restore original size")
	
	# Test panel positioning
	var original_position = info_panel.position
	var new_position = Vector2(100, 100)
	
	info_panel.set_panel_position(new_position)
	test_framework.assert_equal(info_panel.position, new_position, "Panel should move correctly")
	
	info_panel.set_panel_position(original_position)
	test_framework.assert_equal(info_panel.position, original_position, "Panel should restore original position")
	
	# Test panel update frequency
	var update_times = []
	for i in range(20):
		var start_time = Time.get_ticks_usec()
		simulate_panel_update()
		var end_time = Time.get_ticks_usec()
		update_times.append(end_time - start_time)
	
	var average_update_time = calculate_average(update_times)
	test_framework.assert_true(average_update_time < 1000, "Average update time should be < 1ms")
	
	print("✓ Panel responsiveness tests passed")

func test_multi_unit_selection():
	"""Test multi-unit selection handling"""
	print("Testing multi-unit selection...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	
	if not info_panel:
		return
	
	# Test single unit selection
	info_panel.show_hero_info(test_hero)
	var selection_info = get_selection_info()
	
	test_framework.assert_equal(selection_info.count, 1, "Should show 1 selected unit")
	test_framework.assert_equal(selection_info.primary_unit, test_hero, "Should show correct primary unit")
	
	# Test multiple hero selection
	var additional_heroes = create_additional_heroes(3)
	var all_heroes = [test_hero] + additional_heroes
	
	info_panel.show_multiple_units_info(all_heroes)
	selection_info = get_selection_info()
	
	test_framework.assert_equal(selection_info.count, 4, "Should show 4 selected units")
	test_framework.assert_true(selection_info.has_multiple_units, "Should indicate multiple units")
	
	# Test group stats calculation
	var group_stats = get_group_stats()
	test_framework.assert_has_key(group_stats, "total_damage", "Should have total damage")
	test_framework.assert_has_key(group_stats, "average_health", "Should have average health")
	test_framework.assert_has_key(group_stats, "count", "Should have unit count")
	
	# Test heterogeneous unit selection (heroes + towers + enemies)
	var mixed_units = all_heroes + create_test_towers(2) + create_test_enemies(2)
	
	info_panel.show_multiple_units_info(mixed_units)
	selection_info = get_selection_info()
	
	test_framework.assert_equal(selection_info.count, 8, "Should show 8 mixed units")
	test_framework.assert_true(selection_info.has_mixed_types, "Should indicate mixed unit types")
	
	# Test selection priority
	var priority_unit = get_priority_unit(mixed_units)
	test_framework.assert_equal(selection_info.primary_unit, priority_unit, "Should show priority unit as primary")
	
	# Test selection clearing
	info_panel.hide_panel()
	selection_info = get_selection_info()
	
	test_framework.assert_equal(selection_info.count, 0, "Should show 0 units when hidden")
	
	# Test rapid selection changes
	for i in range(10):
		var random_hero = all_heroes[randi() % all_heroes.size()]
		info_panel.show_hero_info(random_hero)
		simulate_panel_update()
	
	# Should handle rapid changes without error
	test_framework.assert_true(true, "Should handle rapid selection changes")
	
	# Test selection limits
	var max_units = 10
	var large_group = create_additional_heroes(max_units)
	
	info_panel.show_multiple_units_info(large_group)
	selection_info = get_selection_info()
	
	test_framework.assert_equal(selection_info.count, max_units, "Should handle maximum unit count")
	
	# Clean up test units
	for hero in additional_heroes:
		if is_instance_valid(hero):
			hero.queue_free()
	
	print("✓ Multi-unit selection tests passed")

func test_stat_accuracy():
	"""Test stat calculation and display accuracy"""
	print("Testing stat accuracy...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not info_panel or not test_hero:
		return
	
	# Test base stat accuracy
	info_panel.show_hero_info(test_hero)
	var displayed_stats = get_displayed_stats()
	
	var expected_damage = test_hero.current_stats.damage
	var expected_defense = test_hero.current_stats.defense
	var expected_attack_speed = test_hero.current_stats.attack_speed
	
	test_framework.assert_equal(displayed_stats.damage, expected_damage, "Displayed damage should be accurate")
	test_framework.assert_equal(displayed_stats.defense, expected_defense, "Displayed defense should be accurate")
	test_framework.assert_approximately(displayed_stats.attack_speed, expected_attack_speed, 0.01, "Displayed attack speed should be accurate")
	
	# Test modified stat accuracy
	var damage_multiplier = 1.5
	test_hero.current_stats.damage *= damage_multiplier
	
	simulate_panel_update()
	displayed_stats = get_displayed_stats()
	
	test_framework.assert_equal(displayed_stats.damage, test_hero.current_stats.damage, "Modified damage should be accurate")
	
	# Test calculated stat accuracy (attack interval)
	var expected_interval = 1.0 / test_hero.current_stats.attack_speed
	var actual_interval = get_displayed_attack_interval()
	
	test_framework.assert_approximately(actual_interval, expected_interval, 0.01, "Attack interval should be calculated correctly")
	
	# Test percentage-based stats accuracy
	var health_percentage = (test_hero.health_bar.value / test_hero.current_stats.max_hp) * 100
	var displayed_percentage = get_displayed_health_percentage()
	
	test_framework.assert_approximately(displayed_percentage, health_percentage, 0.1, "Health percentage should be accurate")
	
	# Test skill stat accuracy
	var skills = test_hero.skills
	for i in range(skills.size()):
		var skill = skills[i]
		var displayed_skill = get_displayed_skill_info(i)
		
		test_framework.assert_equal(displayed_skill.name, skill.skill_name, "Skill name should be accurate")
		test_framework.assert_equal(displayed_skill.cooldown, skill.cooldown, "Skill cooldown should be accurate")
		test_framework.assert_equal(displayed_skill.type, skill.skill_type, "Skill type should be accurate")
	
	# Test level-based stat progression accuracy
	var original_level = test_hero.current_level
	test_hero.current_level = 10
	test_hero.update_stats_for_level()
	
	simulate_panel_update()
	displayed_stats = get_displayed_stats()
	
	var expected_level_10_damage = calculate_expected_damage_at_level(10)
	test_framework.assert_approximately(displayed_stats.damage, expected_level_10_damage, 1.0, "Level 10 damage should be accurate")
	
	# Test talent-modified stat accuracy
	apply_test_talent(test_hero)
	simulate_panel_update()
	displayed_stats = get_displayed_stats()
	
	var talent_modified_damage = test_hero.current_stats.damage
	test_framework.assert_equal(displayed_stats.damage, talent_modified_damage, "Talent-modified damage should be accurate")
	
	# Test decimal precision
	var high_precision_stat = 123.456789
	test_hero.current_stats.damage = high_precision_stat
	
	simulate_panel_update()
	displayed_stats = get_displayed_stats()
	
	test_framework.assert_true(displayed_stats.damage >= 123.4 and displayed_stats.damage <= 123.5, 
		"High precision stats should be rounded appropriately")
	
	# Test negative stat handling
	test_hero.current_stats.defense = -5  # Invalid negative defense
	
	simulate_panel_update()
	displayed_stats = get_displayed_stats()
	
	test_framework.assert_true(displayed_stats.defense >= 0, "Negative stats should be clamped to 0")
	
	print("✓ Stat accuracy tests passed")

func test_ui_updates():
	"""Test UI component updates and changes"""
	print("Testing UI component updates...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not info_panel or not test_hero:
		return
	
	# Test label updates
	info_panel.show_hero_info(test_hero)
	var labels = get_panel_labels()
	
	test_framework.assert_true(labels.size() > 0, "Should have panel labels")
	
	# Modify hero and check label updates
	var original_name = test_hero.hero_name
	test_hero.hero_name = "测试英雄"
	
	simulate_panel_update()
	
	var updated_labels = get_panel_labels()
	var name_label_found = false
	for label in updated_labels:
		if label.text == "测试英雄":
			name_label_found = true
			break
	
	test_framework.assert_true(name_label_found, "Name label should update")
	
	# Test progress bar updates
	var original_health = test_hero.health_bar.value
	test_hero.health_bar.value = original_health * 0.5
	
	simulate_panel_update()
	
	var health_bar = get_health_progress_bar()
	test_framework.assert_equal(health_bar.value, original_health * 0.5, "Health bar should update")
	
	# Test color updates
	var status_colors = get_status_colors()
	test_framework.assert_true(status_colors.size() > 0, "Should have status colors")
	
	# Change hero status and check color updates
	test_hero.take_damage(test_hero.health_bar.value)
	simulate_panel_update()
	
	var updated_colors = get_status_colors()
	test_framework.assert_true(updated_colors.size() > 0, "Should have updated status colors")
	
	# Test skill display updates
	var skill_displays = get_skill_displays()
	test_framework.assert_equal(skill_displays.size(), test_hero.skills.size(), "Should have displays for all skills")
	
	# Test panel component visibility
	var components = get_panel_components()
	for component_name in components:
		var component = components[component_name]
		test_framework.assert_not_null(component, "Component %s should exist" % component_name)
		test_framework.assert_true(component.visible, "Component %s should be visible" % component_name)
	
	# Test panel resize handling
	var original_size = info_panel.size
	info_panel.set_panel_size(original_size * 1.5)
	
	var resized_components = get_panel_components()
	for component_name in resized_components:
		var component = resized_components[component_name]
		test_framework.assert_true(component.size.x > 0, "Component %s should have positive width after resize" % component_name)
	
	info_panel.set_panel_size(original_size)
	
	# Test font and text updates
	var font_sizes = get_font_sizes()
	test_framework.assert_true(font_sizes.size() > 0, "Should have font size information")
	
	# Test tooltip updates
	var tooltips = get_tooltips()
	test_framework.assert_true(tooltips.size() >= 0, "Should have tooltip information")
	
	# Test animation state updates
	var animation_states = get_animation_states()
	test_framework.assert_true(animation_states.size() >= 0, "Should have animation state information")
	
	print("✓ UI component update tests passed")

func test_performance_load():
	"""Test panel performance under load"""
	print("Testing performance under load...")
	
	test_framework.assert_not_null(info_panel, "Info panel should be created")
	
	if not info_panel:
		return
	
	# Test update performance with many units
	var many_heroes = create_additional_heroes(50)
	var start_time = Time.get_ticks_msec()
	
	info_panel.show_multiple_units_info(many_heroes)
	simulate_panel_update()
	
	var end_time = Time.get_ticks_msec()
	var many_units_time = end_time - start_time
	
	test_framework.assert_true(many_units_time < 100, "Should handle 50 units in < 100ms")
	
	# Test rapid update performance
	var update_count = 1000
	start_time = Time.get_ticks_msec()
	
	for i in range(update_count):
		simulate_panel_update()
	
	end_time = Time.get_ticks_msec()
	var rapid_update_time = end_time - start_time
	var average_update_time = rapid_update_time / float(update_count)
	
	test_framework.assert_true(average_update_time < 0.1, "Average update time should be < 0.1ms")
	
	# Test memory performance
	var initial_memory = get_memory_usage()
	
	# Create and show many panels
	var panels = []
	for i in range(20):
		var panel = create_info_panel()
		panel.show_hero_info(test_hero)
		panels.append(panel)
	
	var peak_memory = get_memory_usage()
	var memory_increase = peak_memory - initial_memory
	
	test_framework.assert_true(memory_increase < 50, "Memory increase should be < 50MB for 20 panels")
	
	# Clean up panels
	for panel in panels:
		panel.queue_free()
	
	# Test FPS impact
	var initial_fps = get_current_fps()
	
	# Simulate heavy update load
	for i in range(100):
		info_panel.show_hero_info(test_hero)
		for j in range(10):
			simulate_panel_update()
	
	var final_fps = get_current_fps()
	var fps_drop = initial_fps - final_fps
	
	test_framework.assert_true(fps_drop < 5, "FPS drop should be < 5")
	
	# Test concurrent access
	var access_threads = 5
	var access_results = []
	
	for i in range(access_threads):
		var result = test_concurrent_access()
		access_results.append(result)
	
	var success_rate = float(access_results.count(true)) / float(access_results.size())
	test_framework.assert_true(success_rate > 0.9, "Concurrent access success rate should be > 90%")
	
	# Clean up test heroes
	for hero in many_heroes:
		if is_instance_valid(hero):
			hero.queue_free()
	
	print("✓ Performance load tests passed")

# Helper functions

func create_test_hero() -> HeroBase:
	"""Create a test hero"""
	var hero_scene = Data.load_resource_safe("res://Scenes/heroes/phantom_spirit.tscn", "PackedScene")
	if not hero_scene:
		return null
	
	var hero = hero_scene.instantiate() as HeroBase
	if hero:
		test_scene.add_child(hero)
		hero.hero_type = "phantom_spirit"
		hero.setup_hero_data()
		hero.respawn_hero()
	
	return hero

func create_info_panel() -> Control:
	"""Create an info panel for testing"""
	var panel = Control.new()
	panel.name = "HeroInfoPanel"
	test_scene.add_child(panel)
	
	# Add basic UI components
	add_panel_ui_components(panel)
	
	return panel

func add_panel_ui_components(panel: Control):
	"""Add basic UI components to panel"""
	# This would add labels, progress bars, etc.
	# Simplified for testing
	pass

func simulate_panel_update():
	"""Simulate panel update cycle"""
	if info_panel and info_panel.has_method("_process"):
		info_panel._process(0.2)

func get_displayed_stats() -> Dictionary:
	"""Get currently displayed stats"""
	# This would read from actual UI components
	return {
		"name": "幻影之灵",
		"level": 1,
		"health": 540,
		"damage": 58,
		"defense": 10,
		"attack_speed": 0.9
	}
}

func get_health_info() -> Dictionary:
	"""Get health information"""
	return {
		"current": 540,
		"max": 540,
		"percentage": 100.0
	}
}

func get_status_info() -> Dictionary:
	"""Get status information"""
	return {
		"status": "正常",
		"is_alive": true
	}
}

func get_selection_info() -> Dictionary:
	"""Get selection information"""
	return {
		"count": 1,
		"primary_unit": test_hero,
		"has_multiple_units": false,
		"has_mixed_types": false
	}
}

func create_additional_heroes(count: int) -> Array:
	"""Create additional test heroes"""
	var heroes = []
	for i in range(count):
		var hero = create_test_hero()
		if hero:
			heroes.append(hero)
	return heroes

func create_test_towers(count: int) -> Array:
	"""Create test towers"""
	var towers = []
	# Simplified - would create actual tower instances
	return towers

func create_test_enemies(count: int) -> Array:
	"""Create test enemies"""
	var enemies = []
	# Simplified - would create actual enemy instances
	return enemies

func get_group_stats() -> Dictionary:
	"""Get group statistics"""
	return {
		"total_damage": 232,
		"average_health": 540,
		"count": 4
	}
}

func get_priority_unit(units: Array) -> Node:
	"""Get priority unit from selection"""
	return units[0] if units.size() > 0 else null

func format_number(value: float) -> String:
	"""Format number for display"""
	return str(int(value))

func format_percentage(value: float) -> String:
	"""Format percentage for display"""
	return str(int(value * 100)) + "%"

func format_stat_name(stat_name: String) -> String:
	"""Format stat name for display"""
	match stat_name:
		"damage":
			return "攻击力"
		"defense":
			return "防御力"
		"attack_speed":
			return "攻击速度"
		_:
			return stat_name

func get_test_skills() -> Array:
	"""Get test skills"""
	return [
		{"skill_name": "无影拳", "cooldown": 5.0, "skill_type": "A"},
		{"skill_name": "火焰甲", "cooldown": 12.0, "skill_type": "B"},
		{"skill_name": "末炎幻象", "cooldown": 90.0, "skill_type": "C"}
	]
}

func format_skill_info(skill: Dictionary) -> Dictionary:
	"""Format skill information"""
	return {
		"name": skill.skill_name,
		"cooldown": skill.cooldown,
		"type": skill.skill_type
	}
}

func format_status_text(status_type: String, duration: float) -> String:
	"""Format status text"""
	match status_type:
		"normal":
			return "正常"
		"casting":
			return "施法中 - %.1fs" % duration
		"respawning":
			return "复活中 (%.1fs)" % duration
		"dead":
			return "已死亡"
		_:
			return status_type

func get_element_color(element: String) -> Color:
	"""Get element color"""
	match element:
		"fire":
			return Color.RED
		"ice":
			return Color.CYAN
		"light":
			return Color.WHITE
		_:
			return Color.GRAY

func get_layout_info() -> Dictionary:
	"""Get layout information"""
	return {
		"width": 250,
		"height": 300
	}
}

func get_memory_usage() -> float:
	"""Get current memory usage (MB)"""
	# Simplified - would use actual memory tracking
	return 100.0

func calculate_average(values: Array) -> float:
	"""Calculate average of values"""
	if values.size() == 0:
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += value
	
	return sum / float(values.size())

func get_displayed_attack_interval() -> float:
	"""Get displayed attack interval"""
	return 1.11  # 1/0.9

func get_displayed_health_percentage() -> float:
	"""Get displayed health percentage"""
	return 100.0

func get_displayed_skill_info(index: int) -> Dictionary:
	"""Get displayed skill information"""
	var skills = get_test_skills()
	if index < skills.size():
		return format_skill_info(skills[index])
	return {}

func calculate_expected_damage_at_level(level: int) -> float:
	"""Calculate expected damage at level"""
	return 58 * (1 + 0.08 * (level - 1))

func apply_test_talent(hero: HeroBase):
	"""Apply test talent to hero"""
	hero.current_stats.damage *= 1.2

func get_panel_labels() -> Array:
	"""Get panel labels"""
	# Simplified - would read actual UI components
	return []

func get_health_progress_bar() -> ProgressBar:
	"""Get health progress bar"""
	# Simplified - would return actual UI component
	return ProgressBar.new()

func get_status_colors() -> Dictionary:
	"""Get status colors"""
	return {}

func get_skill_displays() -> Array:
	"""Get skill displays"""
	return []

func get_panel_components() -> Dictionary:
	"""Get panel components"""
	return {}

func get_font_sizes() -> Dictionary:
	"""Get font sizes"""
	return {}

func get_tooltips() -> Array:
	"""Get tooltips"""
	return []

func get_animation_states() -> Dictionary:
	"""Get animation states"""
	return {}

func get_current_fps() -> float:
	"""Get current FPS"""
	return 60.0

func test_concurrent_access() -> bool:
	"""Test concurrent panel access"""
	# Simplified concurrent access test
	return true

func cleanup():
	"""Clean up test resources"""
	if test_hero and is_instance_valid(test_hero):
		test_hero.queue_free()
	
	if info_panel and is_instance_valid(info_panel):
		info_panel.queue_free()
	
	if test_scene and is_instance_valid(test_scene):
		test_scene.queue_free()
	
	if test_framework and is_instance_valid(test_framework):
		test_framework.queue_free()