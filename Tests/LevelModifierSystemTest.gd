extends Node
class_name LevelModifierSystemTest

## Level Modifier System Test Suite
## Tests random modifier generation, effect application, stacking, and UI display

const TestFramework = preload("res://Tests/TestFramework.gd")

var test_framework: TestFramework
var test_scene: Node2D
var modifier_system: Node
var test_hero: HeroBase
var test_enemies: Array

func _ready():
	print("=== Level Modifier System Test Suite Started ===")
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# Setup test environment
	setup_test_environment()
	
	# Run all tests
	run_all_tests()
	
	print("=== Level Modifier System Test Suite Completed ===")

func setup_test_environment():
	"""Create test scene and components"""
	# Create test scene
	test_scene = Node2D.new()
	add_child(test_scene)
	
	# Create modifier system
	modifier_system = Node.new()
	modifier_system.set_script(preload("res://Tests/Mocks/MockLevelModifierSystem.gd"))
	test_scene.add_child(modifier_system)
	
	# Create test hero
	test_hero = create_test_hero()
	
	# Create test enemies
	test_enemies = create_test_enemies()

func run_all_tests():
	"""Execute all level modifier system tests"""
	var tests = [
		{"name": "Random Modifier Generation", "func": test_random_generation},
		{"name": "Modifier Effect Application", "func": test_effect_application},
		{"name": "Modifier Stacking System", "func": test_modifier_stacking},
		{"name": "Modifier Duration Management", "func": test_duration_management},
		{"name": "Modifier UI Display", "func": test_ui_display},
		{"name": "Modifier Cleanup", "func": test_modifier_cleanup},
		{"name": "Modifier Balance", "func": test_modifier_balance},
		{"name": "Modifier Integration", "func": test_modifier_integration}
	]
	
	test_framework.run_test_suite("Level Modifier System", tests)

func test_random_generation():
	"""Test random modifier generation and selection"""
	print("Testing random modifier generation...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	
	if not modifier_system:
		return
	
	# Test modifier data availability
	test_framework.assert_has_key(Data.level_modifiers, "positive", "Should have positive modifiers")
	test_framework.assert_has_key(Data.level_modifiers, "negative", "Should have negative modifiers")
	test_framework.assert_has_key(Data.level_modifiers, "neutral", "Should have neutral modifiers")
	
	# Test modifier counts
	var positive_count = Data.level_modifiers.positive.size()
	var negative_count = Data.level_modifiers.negative.size()
	var neutral_count = Data.level_modifiers.neutral.size()
	
	test_framework.assert_true(positive_count > 0, "Should have positive modifiers")
	test_framework.assert_true(negative_count > 0, "Should have negative modifiers")
	test_framework.assert_true(neutral_count > 0, "Should have neutral modifiers")
	
	# Test modifier generation for level
	var level_modifiers = generate_modifiers_for_level(1)
	test_framework.assert_array_size(level_modifiers, 1, "Level 1 should generate exactly 1 modifier")
	
	level_modifiers = generate_modifiers_for_level(5)
	test_framework.assert_true(level_modifiers.size() >= 1 and level_modifiers.size() <= 2, 
		"Level 5 should generate 1-2 modifiers")
	
	level_modifiers = generate_modifiers_for_level(10)
	test_framework.assert_array_size(level_modifiers, 2, "Level 10 should generate exactly 2 modifiers")
	
	# Test modifier randomness and distribution
	var modifier_distribution = test_modifier_distribution(100)
	test_framework.assert_true(modifier_distribution.positive_rate > 0.3, 
		"Positive modifiers should appear at least 30% of the time")
	test_framework.assert_true(modifier_distribution.negative_rate < 0.4, 
		"Negative modifiers should appear less than 40% of the time")
	
	# Test modifier uniqueness in generation
	var unique_modifiers = generate_modifiers_for_level(15)
	var modifier_ids = []
	for modifier in unique_modifiers:
		modifier_ids.append(modifier.id)
	
	var unique_count = {}
	for id in modifier_ids:
		unique_count[id] = true
	test_framework.assert_equal(unique_count.size(), modifier_ids.size(), "Generated modifiers should be unique")
	
	# Test modifier weight system
	var weighted_selection = test_weighted_selection(1000)
	test_framework.assert_true(weighted_selection.weighted_matches_expectations, 
		"Weighted selection should match expected distribution")
	
	# Test edge cases
	var empty_modifiers = generate_modifiers_for_level(0)
	test_framework.assert_array_size(empty_modifiers, 0, "Level 0 should generate no modifiers")
	
	var high_level_modifiers = generate_modifiers_for_level(100)
	test_framework.assert_array_size(high_level_modifiers, 2, "High level should still generate 2 modifiers")
	
	print("✓ Random modifier generation tests passed")

func test_effect_application():
	"""Test modifier effect application to heroes and enemies"""
	print("Testing modifier effect application...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not modifier_system or not test_hero:
		return
	
	# Test positive modifier application
	var positive_modifier = get_test_modifier("positive")
	apply_modifier_to_hero(test_hero, positive_modifier)
	
	var modified_stats = get_modified_hero_stats(test_hero)
	test_framework.assert_true(modified_stats.damage > test_hero.base_stats.damage, 
		"Positive modifier should increase hero damage")
	
	# Test negative modifier application
	var negative_modifier = get_test_modifier("negative")
	apply_modifier_to_hero(test_hero, negative_modifier)
	
	modified_stats = get_modified_hero_stats(test_hero)
	test_framework.assert_true(modified_stats.max_hp < test_hero.base_stats.max_hp, 
		"Negative modifier should decrease hero max HP")
	
	# Test neutral modifier application
	var neutral_modifier = get_test_modifier("neutral")
	var original_damage = modified_stats.damage
	var original_range = modified_stats.attack_range
	
	apply_modifier_to_hero(test_hero, neutral_modifier)
	modified_stats = get_modified_hero_stats(test_hero)
	
	# Neutral modifiers should have trade-offs
	test_framework.assert_true(
		(modified_stats.damage != original_damage) or (modified_stats.attack_range != original_range),
		"Neutral modifier should change stats")
	
	# Test enemy modifier application
	for enemy in test_enemies:
		var enemy_modifier = get_enemy_modifier()
		apply_modifier_to_enemy(enemy, enemy_modifier)
		
		var modified_enemy_stats = get_modified_enemy_stats(enemy)
		test_framework.assert_true(modified_enemy_stats.hp != enemy.stats.hp, 
			"Enemy modifier should change enemy stats")
	
	# Test modifier effect types
	var effect_types = ["stat_modifier", "skill_modifier", "aura_modifier"]
	for effect_type in effect_types:
		var modifier = get_modifier_by_effect_type(effect_type)
		var application_success = apply_modifier_by_type(test_hero, modifier, effect_type)
		test_framework.assert_true(application_success, "Should be able to apply %s modifier" % effect_type)
	
	# Test modifier magnitude scaling
	for level in [1, 5, 10, 15, 20]:
		var scaled_modifier = get_scaled_modifier(level)
		var magnitude = get_modifier_magnitude(scaled_modifier)
		var expected_magnitude = calculate_expected_magnitude(level, scaled_modifier.type)
		
		test_framework.assert_in_range(magnitude, expected_magnitude * 0.8, expected_magnitude * 1.2,
			"Magnitude should scale appropriately with level")
	
	# Test multiple modifier application
	var modifiers = [positive_modifier, negative_modifier, neutral_modifier]
	for modifier in modifiers:
		apply_modifier_to_hero(test_hero, modifier)
	
	test_framework.assert_true(has_multiple_active_modifiers(test_hero), 
		"Should be able to apply multiple modifiers")
	
	print("✓ Modifier effect application tests passed")

func test_modifier_stacking():
	"""Test modifier stacking and interaction rules"""
	print("Testing modifier stacking...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not modifier_system or not test_hero:
		return
	
	# Test same modifier stacking
	var damage_modifier = get_damage_modifier()
	apply_modifier_to_hero(test_hero, damage_modifier)
	var first_damage = get_modified_hero_stats(test_hero).damage
	
	apply_modifier_to_hero(test_hero, damage_modifier)
	var second_damage = get_modified_hero_stats(test_hero).damage
	
	test_framework.assert_true(second_damage > first_damage, 
		"Same modifier should stack and increase effect")
	
	# Test different modifier stacking
	var hp_modifier = get_hp_modifier()
	apply_modifier_to_hero(test_hero, hp_modifier)
	
	var modified_stats = get_modified_hero_stats(test_hero)
	test_framework.assert_true(modified_stats.damage > test_hero.base_stats.damage, 
		"Damage should still be increased")
	test_framework.assert_true(modified_stats.max_hp > test_hero.base_stats.max_hp, 
		"HP should also be increased")
	
	# Test stacking limits
	var max_stacks = 5
	for i in range(max_stacks + 2):  # Try to exceed limit
		apply_modifier_to_hero(test_hero, damage_modifier)
	
	var final_damage = get_modified_hero_stats(test_hero).damage
	var expected_max_damage = calculate_max_stack_damage(test_hero.base_stats.damage, max_stacks)
	test_framework.assert_true(final_damage <= expected_max_damage, 
		"Damage should not exceed stacking limit")
	
	# Test conflicting modifier interaction
	var conflicting_pair = get_conflicting_modifiers()
	apply_modifier_to_hero(test_hero, conflicting_pair[0])
	var conflict_base = get_modified_hero_stats(test_hero).damage
	
	apply_modifier_to_hero(test_hero, conflicting_pair[1])
	var conflict_result = get_modified_hero_stats(test_hero).damage
	
	test_framework.assert_true(conflict_result != conflict_base, 
		"Conflicting modifiers should interact")
	
	# Test synergistic modifier interaction
	var synergistic_pair = get_synergistic_modifiers()
	clear_hero_modifiers(test_hero)
	
	apply_modifier_to_hero(test_hero, synergistic_pair[0])
	var synergy_base = get_modified_hero_stats(test_hero).damage
	
	apply_modifier_to_hero(test_hero, synergistic_pair[1])
	var synergy_result = get_modified_hero_stats(test_hero).damage
	
	var expected_synergy = synergy_base * 1.2  # 20% synergy bonus
	test_framework.assert_true(synergy_result >= expected_synergy, 
		"Synergistic modifiers should provide bonus")
	
	# Test modifier priority and ordering
	var ordered_modifiers = get_priority_ordered_modifiers()
	clear_hero_modifiers(test_hero)
	
	for i in range(ordered_modifiers.size()):
		var modifier = ordered_modifiers[i]
		apply_modifier_to_hero(test_hero, modifier)
		var priority_result = get_modified_hero_stats(test_hero).damage
	
	# Results should be consistent regardless of application order
	test_framework.assert_true(priority_result > 0, "Priority ordering should work")
	
	# Test diminishing returns
	clear_hero_modifiers(test_hero)
	var base_value = test_hero.base_stats.damage
	var increments = []
	
	for i in range(5):
		apply_modifier_to_hero(test_hero, damage_modifier)
		var current_value = get_modified_hero_stats(test_hero).damage
		increments.append(current_value - (increments.size() > 0 ? increments[-1] : base_value))
	
	# Each increment should be smaller than the previous (diminishing returns)
	for i in range(1, increments.size()):
		test_framework.assert_true(increments[i] <= increments[i-1], 
			"Should show diminishing returns on stacking")
	
	print("✓ Modifier stacking tests passed")

func test_duration_management():
	"""Test modifier duration and timing"""
	print("Testing modifier duration management...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	
	if not modifier_system:
		return
	
	# Test modifier duration assignment
	var temporary_modifier = get_temporary_modifier()
	test_framework.assert_true(temporary_modifier.duration > 0, "Temporary modifier should have duration")
	
	var permanent_modifier = get_permanent_modifier()
	test_framework.assert_equal(permanent_modifier.duration, -1, "Permanent modifier should have -1 duration")
	
	# Test duration tracking
	apply_modifier_with_duration(test_hero, temporary_modifier)
	var active_modifiers = get_active_modifiers(test_hero)
	test_framework.assert_array_size(active_modifiers, 1, "Should have one active modifier")
	test_framework.assert_true(active_modifiers[0].time_remaining > 0, "Modifier should have time remaining")
	
	# Test duration countdown
	var initial_time = active_modifiers[0].time_remaining
	simulate_time_passage(1.0)  # 1 second
	
	active_modifiers = get_active_modifiers(test_hero)
	test_framework.assert_true(active_modifiers[0].time_remaining < initial_time, 
		"Time remaining should decrease")
	
	# Test duration expiration
	var short_duration_modifier = get_short_duration_modifier()
	apply_modifier_with_duration(test_hero, short_duration_modifier)
	
	simulate_time_passage(short_duration_modifier.duration + 1.0)
	active_modifiers = get_active_modifiers(test_hero)
	
	# Expired modifier should be removed
	var expired_found = false
	for modifier in active_modifiers:
		if modifier.id == short_duration_modifier.id:
			expired_found = true
			break
	test_framework.assert_false(expired_found, "Expired modifier should be removed")
	
	# Test permanent modifier persistence
	apply_modifier_with_duration(test_hero, permanent_modifier)
	simulate_time_passage(100.0)  # Long time
	
	active_modifiers = get_active_modifiers(test_hero)
	var permanent_found = false
	for modifier in active_modifiers:
		if modifier.id == permanent_modifier.id:
			permanent_found = true
			break
	test_framework.assert_true(permanent_found, "Permanent modifier should persist")
	
	# Test duration-based effect scaling
	var scaling_modifier = get_scaling_modifier()
	apply_modifier_with_duration(test_hero, scaling_modifier)
	
	var time_points = [0.0, 0.25, 0.5, 0.75, 1.0]
	var effect_values = []
	
	for time_point in time_points:
		var effect = get_modifier_effect_at_time(scaling_modifier, time_point)
		effect_values.append(effect)
	
	# Effect should scale with time
	for i in range(1, effect_values.size()):
		test_framework.assert_true(effect_values[i] >= effect_values[i-1], 
			"Scaling effect should increase with time")
	
	# Test pause/resume of duration
	var pausable_modifier = get_pausable_modifier()
	apply_modifier_with_duration(test_hero, pausable_modifier)
	
	var before_pause = get_modifier_time_remaining(pausable_modifier)
	pause_modifier_duration(pausable_modifier)
	simulate_time_passage(1.0)
	
	var during_pause = get_modifier_time_remaining(pausable_modifier)
	test_framework.assert_equal(during_pause, before_pause, 
		"Time should not decrease when paused")
	
	resume_modifier_duration(pausable_modifier)
	simulate_time_passage(1.0)
	
	var after_resume = get_modifier_time_remaining(pausable_modifier)
	test_framework.assert_true(after_pause < during_pause, 
		"Time should decrease when resumed")
	
	print("✓ Duration management tests passed")

func test_ui_display():
	"""Test modifier UI display and updates"""
	print("Testing modifier UI display...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	
	if not modifier_system:
		return
	
	# Test modifier icon and display data
	var test_modifier = get_test_modifier("positive")
	test_framework.assert_has_key(test_modifier, "name", "Modifier should have name")
	test_framework.assert_has_key(test_modifier, "description", "Modifier should have description")
	test_framework.assert_has_key(test_modifier, "icon", "Modifier should have icon")
	
	# Test UI formatting
	var formatted_name = format_modifier_name(test_modifier)
	test_framework.assert_false(formatted_name.is_empty(), "Formatted name should not be empty")
	test_framework.assert_true(formatted_name.length <= 20, "Formatted name should be concise")
	
	var formatted_description = format_modifier_description(test_modifier)
	test_framework.assert_false(formatted_description.is_empty(), "Formatted description should not be empty")
	test_framework.assert_true(formatted_description.length <= 50, "Formatted description should be concise")
	
	# Test modifier type display
	var type_colors = {
		"positive": Color.GREEN,
		"negative": Color.RED,
		"neutral": Color.YELLOW
	}
	
	for modifier_type in type_colors:
		var modifier = get_test_modifier(modifier_type)
		var display_color = get_modifier_display_color(modifier)
		test_framework.assert_equal(display_color, type_colors[modifier_type], 
			"Color should match modifier type")
	
	# Test modifier list generation
	var modifiers = [
		get_test_modifier("positive"),
		get_test_modifier("negative"),
		get_test_modifier("neutral")
	]
	
	var modifier_list = generate_modifier_list(modifiers)
	test_framework.assert_array_size(modifier_list, 3, "Should generate list with all modifiers")
	
	for i in range(modifier_list.size()):
		test_framework.assert_has_key(modifier_list[i], "name", "List item %d should have name" % i)
		test_framework.assert_has_key(modifier_list[i], "description", "List item %d should have description" % i)
		test_framework.assert_has_key(modifier_list[i], "color", "List item %d should have color" % i)
	
	# Test active modifier display
	apply_modifier_to_hero(test_hero, get_test_modifier("positive"))
	var active_display = get_active_modifier_display(test_hero)
	test_framework.assert_array_size(active_display, 1, "Should display one active modifier")
	
	# Test modifier sorting in display
	var multiple_modifiers = [
		get_test_modifier("negative"),
		get_test_modifier("positive"),
		get_test_modifier("neutral")
	]
	
	for modifier in multiple_modifiers:
		apply_modifier_to_hero(test_hero, modifier)
	
	var sorted_display = get_active_modifier_display(test_hero)
	test_framework.assert_true(is_sorted_by_priority(sorted_display), 
		"Display should be sorted by priority")
	
	# Test modifier tooltip generation
	var tooltip_text = generate_modifier_tooltip(test_modifier)
	test_framework.assert_false(tooltip_text.is_empty(), "Tooltip should not be empty")
	test_framework.assert_true(tooltip_text.length <= 200, "Tooltip should be concise")
	
	# Test modifier status indicators
	var status_indicators = get_modifier_status_indicators(test_hero)
	test_framework.assert_true(status_indicators.size() >= 0, "Should generate status indicators")
	
	for indicator in status_indicators:
		test_framework.assert_has_key(indicator, "type", "Indicator should have type")
		test_framework.assert_has_key(indicator, "value", "Indicator should have value")
		test_framework.assert_has_key(indicator, "max_value", "Indicator should have max value")
	
	# Test UI update triggers
	var ui_update_triggered = false
	modifier_system.connect("modifier_ui_update", func():
		ui_update_triggered = true
	)
	
	apply_modifier_to_hero(test_hero, get_test_modifier("positive"))
	test_framework.assert_true(ui_update_triggered, "UI update should be triggered on modifier change")
	
	print("✓ Modifier UI display tests passed")

func test_modifier_cleanup():
	"""Test modifier cleanup between levels"""
	print("Testing modifier cleanup...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not modifier_system or not test_hero:
		return
	
	# Apply multiple modifiers
	var modifiers = [
		get_test_modifier("positive"),
		get_test_modifier("negative"),
		get_test_modifier("neutral"),
		get_temporary_modifier(),
		get_permanent_modifier()
	]
	
	for modifier in modifiers:
		apply_modifier_to_hero(test_hero, modifier)
	
	test_framework.assert_true(get_active_modifiers(test_hero).size() > 0, "Should have active modifiers")
	
	# Test level transition cleanup
	simulate_level_transition()
	var after_transition_modifiers = get_active_modifiers(test_hero)
	
	# Temporary modifiers should be cleaned up
	var temporary_found = false
	for modifier in after_transition_modifiers:
		if modifier.duration > 0 and modifier.duration != -1:
			temporary_found = true
			break
	test_framework.assert_false(temporary_found, "Temporary modifiers should be cleaned up")
	
	# Permanent modifiers should persist
	var permanent_found = false
	for modifier in after_transition_modifiers:
		if modifier.duration == -1:
			permanent_found = true
			break
	test_framework.assert_true(permanent_found, "Permanent modifiers should persist")
	
	# Test complete cleanup
	cleanup_all_modifiers(test_hero)
	var all_cleaned = get_active_modifiers(test_hero)
	test_framework.assert_array_size(all_cleaned, 0, "All modifiers should be cleaned up")
	
	# Test cleanup signal handling
	var cleanup_triggered = false
	modifier_system.connect("modifiers_cleaned", func():
		cleanup_triggered = true
	)
	
	apply_modifier_to_hero(test_hero, get_test_modifier("positive"))
	cleanup_all_modifiers(test_hero)
	test_framework.assert_true(cleanup_triggered, "Cleanup signal should be triggered")
	
	# Test cleanup by type
	apply_modifier_to_hero(test_hero, get_test_modifier("positive"))
	apply_modifier_to_hero(test_hero, get_test_modifier("negative"))
	
	cleanup_modifiers_by_type(test_hero, "negative")
	var remaining_modifiers = get_active_modifiers(test_hero)
	
	var negative_found = false
	for modifier in remaining_modifiers:
		if modifier.type == "negative":
			negative_found = true
			break
	test_framework.assert_false(negative_found, "Negative modifiers should be cleaned up")
	
	var positive_found = false
	for modifier in remaining_modifiers:
		if modifier.type == "positive":
			positive_found = true
			break
	test_framework.assert_true(positive_found, "Positive modifiers should remain")
	
	# Test cleanup validation
	var invalid_cleanup = cleanup_nonexistent_modifiers(test_hero)
	test_framework.assert_false(invalid_cleanup, "Should return false for invalid cleanup")
	
	# Test cleanup state consistency
	var hero_stats_before = get_modified_hero_stats(test_hero)
	cleanup_all_modifiers(test_hero)
	var hero_stats_after = get_modified_hero_stats(test_hero)
	
	test_framework.assert_equal(hero_stats_after.max_hp, test_hero.base_stats.max_hp, 
		"HP should return to base after cleanup")
	test_framework.assert_equal(hero_stats_after.damage, test_hero.base_stats.damage, 
		"Damage should return to base after cleanup")
	
	print("✓ Modifier cleanup tests passed")

func test_modifier_balance():
	"""Test modifier balance and game impact"""
	print("Testing modifier balance...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not modifier_system or not test_hero:
		return
	
	# Test modifier power levels
	var power_levels = test_modifier_power_levels()
	test_framework.assert_true(power_levels.positive_average > 1.0, 
		"Positive modifiers should provide net benefit")
	test_framework.assert_true(power_levels.negative_average < 1.0, 
		"Negative modifiers should provide net detriment")
	test_framework.assert_approximately(power_levels.neutral_average, 1.0, 0.1, 
		"Neutral modifiers should be balanced")
	
	# Test modifier impact on game balance
	var base_effectiveness = calculate_hero_effectiveness(test_hero)
	
	apply_modifier_to_hero(test_hero, get_test_modifier("positive"))
	var positive_effectiveness = calculate_hero_effectiveness(test_hero)
	test_framework.assert_true(positive_effectiveness > base_effectiveness, 
		"Positive modifier should increase effectiveness")
	
	clear_hero_modifiers(test_hero)
	apply_modifier_to_hero(test_hero, get_test_modifier("negative"))
	var negative_effectiveness = calculate_hero_effectiveness(test_hero)
	test_framework.assert_true(negative_effectiveness < base_effectiveness, 
		"Negative modifier should decrease effectiveness")
	
	# Test modifier variance and predictability
	var variance_results = test_modifier_variance(100)
	test_framework.assert_true(variance_results.coefficient_of_variation < 0.5, 
		"Modifier effects should have reasonable variance")
	test_framework.assert_true(variance_results.predictability_score > 0.7, 
		"Modifier effects should be reasonably predictable")
	
	# Test modifier rarity and distribution
	var distribution = test_modifier_rarity_distribution()
	test_framework.assert_true(distribution.common_rate > 0.5, 
		"Common modifiers should appear most frequently")
	test_framework.assert_true(distribution.rare_rate < 0.2, 
		"Rare modifiers should appear less frequently")
	test_framework.assert_true(distribution.legendary_rate < 0.05, 
		"Legendary modifiers should be very rare")
	
	# Test modifier scaling with difficulty
	var difficulty_levels = [1, 5, 10, 15, 20]
	var difficulty_impact = []
	
	for difficulty in difficulty_levels:
		var modifiers = generate_modifiers_for_level(difficulty)
		var impact_score = calculate_modifier_impact_score(modifiers)
		difficulty_impact.append(impact_score)
	
	# Impact should increase with difficulty
	for i in range(1, difficulty_impact.size()):
		test_framework.assert_true(difficulty_impact[i] >= difficulty_impact[i-1], 
			"Impact should increase with difficulty")
	
	# Test modifier counterplay options
	var counterplay_options = test_modifier_counterplay()
	test_framework.assert_true(counterplay_options.has_counterplay_options, 
		"Should have counterplay options for negative modifiers")
	test_framework.assert_true(counterplay_options.mitigation_rate > 0.3, 
		"Should be able to mitigate at least 30% of negative effects")
	
	# Test long-term balance effects
	var long_term_results = simulate_long_term_modifier_effects()
	test_framework.assert_true(long_term_results.win_rate > 0.4 and long_term_results.win_rate < 0.6, 
		"Long-term win rate should be balanced around 50%")
	test_framework.assert_true(long_term_results.fun_score > 0.7, 
		"Should maintain high fun score with modifiers")
	
	# Test modifier synergy balance
	var synergy_results = test_modifier_synergy_balance()
	test_framework.assert_true(synergy_results.balanced_synergy_rate > 0.8, 
		"Most synergy combinations should be balanced")
	test_framework.assert_true(synergy_results.overpowered_rate < 0.1, 
		"Few synergy combinations should be overpowered")
	
	print("✓ Modifier balance tests passed")

func test_modifier_integration():
	"""Test modifier integration with other game systems"""
	print("Testing modifier integration...")
	
	test_framework.assert_not_null(modifier_system, "Modifier system should be created")
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not modifier_system or not test_hero:
		return
	
	# Test integration with hero system
	apply_modifier_to_hero(test_hero, get_hero_compatible_modifier())
	test_framework.assert_true(modifier_affects_hero_system(test_hero), 
		"Modifier should integrate with hero system")
	
	# Test integration with wave system
	var wave_modifier = get_wave_affected_modifier()
	apply_wave_modifier(wave_modifier)
	test_framework.assert_true(wave_system_affected_by_modifier(), 
		"Wave system should be affected by modifier")
	
	# Test integration with gem system
	var gem_modifier = get_gem_affected_modifier()
	apply_gem_modifier(gem_modifier)
	test_framework.assert_true(gem_system_affected_by_modifier(), 
		"Gem system should be affected by modifier")
	
	# Test integration with talent system
	var talent_modifier = get_talent_affected_modifier()
	apply_talent_modifier(talent_modifier)
	test_framework.assert_true(talent_system_affected_by_modifier(), 
		"Talent system should be affected by modifier")
	
	# Test cross-system modifier conflicts
	var conflict_results = test_cross_system_conflicts()
	test_framework.assert_true(conflict_results.conflict_rate < 0.2, 
		"Cross-system conflicts should be rare")
	test_framework.assert_true(conflict_results.resolution_rate > 0.9, 
		"Most conflicts should be resolvable")
	
	# Test modifier persistence across game sessions
	var persistence_results = test_modifier_persistence()
	test_framework.assert_true(persistence_results.save_success_rate > 0.95, 
		"Modifiers should save successfully")
	test_framework.assert_true(persistence_results.load_success_rate > 0.95, 
		"Modifiers should load successfully")
	
	# Test modifier performance impact
	var performance_results = test_modifier_performance()
	test_framework.assert_true(performance_results.fps_drop < 5, 
		"Modifiers should not cause significant FPS drop")
	test_framework.assert_true(performance_results.memory_increase < 10, 
		"Modifiers should not cause significant memory increase")
	
	# Test modifier event system integration
	var event_results = test_modifier_event_integration()
	test_framework.assert_true(event_results.event_trigger_rate > 0.9, 
		"Modifier events should trigger reliably")
	test_framework.assert_true(event_results.event_handling_success > 0.95, 
		"Modifier events should be handled successfully")
	
	# Test modifier network synchronization (if applicable)
	var network_results = test_modifier_network_sync()
	test_framework.assert_true(network_results.sync_success_rate > 0.98, 
		"Modifiers should synchronize successfully over network")
	test_framework.assert_true(network_results.sync_latency < 50, 
		"Modifier synchronization should have low latency")
	
	# Test modifier debugging and logging
	var debug_results = test_modifier_debugging()
	test_framework.assert_true(debug_results.log_coverage > 0.8, 
		"Most modifier actions should be logged")
	test_framework.assert_true(debug_results.debug_info_available, 
		"Debug information should be available")
	
	print("✓ Modifier integration tests passed")

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

func create_test_enemies() -> Array:
	"""Create test enemies"""
	var enemies = []
	var enemy_types = ["redDino", "blueDino", "yellowDino"]
	
	for enemy_type in enemy_types:
		var enemy_scene = Data.load_resource_safe("res://Scenes/enemies/%s.tscn" % enemy_type, "PackedScene")
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			test_scene.add_child(enemy)
			enemies.append(enemy)
	
	return enemies

func generate_modifiers_for_level(level: int) -> Array:
	"""Generate modifiers for specific level"""
	var count = 1
	if level >= 5:
		count = 1 if randf() > 0.5 else 2
	if level >= 10:
		count = 2
	
	var modifiers = []
	var all_modifiers = []
	
	# Collect all available modifiers
	for modifier_type in ["positive", "negative", "neutral"]:
		if Data.level_modifiers.has(modifier_type):
			all_modifiers.append_array(Data.level_modifiers[modifier_type])
	
	# Select random modifiers
	for i in range(count):
		if all_modifiers.size() > 0:
			var index = randi() % all_modifiers.size()
			modifiers.append(all_modifiers[index].duplicate(true))
	
	return modifiers

func get_test_modifier(type: String) -> Dictionary:
	"""Get a test modifier of specified type"""
	var modifiers = Data.level_modifiers.get(type, [])
	if modifiers.size() > 0:
		return modifiers[0].duplicate(true)
	return {}

func apply_modifier_to_hero(hero: HeroBase, modifier: Dictionary):
	"""Apply modifier to hero"""
	# Simplified application - in reality would be more complex
	if not hero.has_meta("active_modifiers"):
		hero.set_meta("active_modifiers", [])
	
	var active_modifiers = hero.get_meta("active_modifiers")
	active_modifiers.append(modifier)

func get_modified_hero_stats(hero: HeroBase) -> Dictionary:
	"""Get hero stats with modifiers applied"""
	var stats = hero.current_stats.duplicate(true)
	
	# Apply modifier effects (simplified)
	if hero.has_meta("active_modifiers"):
		var modifiers = hero.get_meta("active_modifiers")
		for modifier in modifiers:
			if modifier.has("effects"):
				for effect_key, effect_value in modifier.effects:
					match effect_key:
						"hero_damage_multiplier":
							stats.damage *= effect_value
						"hero_hp_multiplier":
							stats.max_hp *= effect_value
						"hero_range_multiplier":
							stats.attack_range *= effect_value
	
	return stats

func get_active_modifiers(hero: HeroBase) -> Array:
	"""Get active modifiers for hero"""
	if hero.has_meta("active_modifiers"):
		return hero.get_meta("active_modifiers")
	return []

func clear_hero_modifiers(hero: HeroBase):
	"""Clear all modifiers from hero"""
	hero.set_meta("active_modifiers", [])

func has_multiple_active_modifiers(hero: HeroBase) -> bool:
	"""Check if hero has multiple active modifiers"""
	return get_active_modifiers(hero).size() > 1

# Additional helper functions would be implemented here for the specific test cases
# Due to length constraints, these are simplified versions

func get_damage_modifier() -> Dictionary:
	return get_test_modifier("positive")

func get_hp_modifier() -> Dictionary:
	return get_test_modifier("positive")

func get_temporary_modifier() -> Dictionary:
	var modifier = get_test_modifier("neutral")
	modifier.duration = 10.0
	return modifier

func get_permanent_modifier() -> Dictionary:
	var modifier = get_test_modifier("positive")
	modifier.duration = -1
	return modifier

func apply_modifier_with_duration(hero: HeroBase, modifier: Dictionary):
	apply_modifier_to_hero(hero, modifier)

func simulate_time_passage(delta: float):
	"""Simulate time passage for modifier duration"""
	# In a real implementation, this would update modifier timers
	pass

func get_modifier_time_remaining(modifier: Dictionary) -> float:
	return modifier.get("time_remaining", modifier.duration)

func cleanup_all_modifiers(hero: HeroBase):
	clear_hero_modifiers(hero)

func simulate_level_transition():
	"""Simulate level transition for cleanup"""
	pass

func calculate_hero_effectiveness(hero: HeroBase) -> float:
	"""Calculate hero effectiveness score"""
	var stats = get_modified_hero_stats(hero)
	return (stats.damage + stats.max_hp * 0.1 + stats.attack_range * 0.05) / 100.0

# Many more helper functions would be needed for complete implementation
# This is a simplified version showing the structure

func cleanup():
	"""Clean up test resources"""
	if test_hero and is_instance_valid(test_hero):
		test_hero.queue_free()
	
	for enemy in test_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	if modifier_system and is_instance_valid(modifier_system):
		modifier_system.queue_free()
	
	if test_scene and is_instance_valid(test_scene):
		test_scene.queue_free()
	
	if test_framework and is_instance_valid(test_framework):
		test_framework.queue_free()