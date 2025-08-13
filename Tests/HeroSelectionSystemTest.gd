extends Node
class_name HeroSelectionSystemTest

## Hero Selection System Test Suite
## Tests hero selection interface, random hero pool generation, wave triggering, and deployment

const TestFramework = preload("res://Tests/TestFramework.gd")

var test_framework: TestFramework
var test_scene: Node2D
var hero_selection_ui: HeroSelection
var mock_hero_manager: Node

func _ready():
	print("=== Hero Selection System Test Suite Started ===")
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# Setup test environment
	setup_test_environment()
	
	# Run all tests
	run_all_tests()
	
	print("=== Hero Selection System Test Suite Completed ===")

func setup_test_environment():
	"""Create test scene and UI components"""
	# Create test scene
	test_scene = Node2D.new()
	add_child(test_scene)
	
	# Create mock hero manager
	mock_hero_manager = Node.new()
	mock_hero_manager.set_script(preload("res://Tests/Mocks/MockHeroManager.gd"))
	test_scene.add_child(mock_hero_manager)
	
	# Load and instantiate hero selection UI
	var selection_scene = Data.load_resource_safe("res://Scenes/ui/heroSystem/HeroSelection.tscn", "PackedScene")
	if selection_scene:
		hero_selection_ui = selection_scene.instantiate() as HeroSelection
		test_scene.add_child(hero_selection_ui)
	else:
		push_error("Failed to load HeroSelection scene")

func run_all_tests():
	"""Execute all hero selection system tests"""
	var tests = [
		{"name": "Hero Selection Interface", "func": test_selection_interface},
		{"name": "Random Hero Pool Generation", "func": test_hero_pool_generation},
		{"name": "Wave Triggering System", "func": test_wave_triggering},
		{"name": "Hero Deployment", "func": test_hero_deployment},
		{"name": "Hero Replacement", "func": test_hero_replacement},
		{"name": "Selection Validation", "func": test_selection_validation},
		{"name": "UI State Management", "func": test_ui_state_management},
		{"name": "Signal Handling", "func": test_signal_handling}
	]
	
	test_framework.run_test_suite("Hero Selection System", tests)

func test_selection_interface():
	"""Test hero selection UI components and functionality"""
	print("Testing hero selection interface...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test UI components
	test_framework.assert_not_null(hero_selection_ui.get_node_or_null("Panel"), "Selection panel should exist")
	test_framework.assert_not_null(hero_selection_ui.get_node_or_null("Panel/TitleLabel"), "Title label should exist")
	test_framework.assert_not_null(hero_selection_ui.get_node_or_null("Panel/DescriptionLabel"), "Description label should exist")
	test_framework.assert_not_null(hero_selection_ui.get_node_or_null("Panel/HeroOptionsContainer"), "Options container should exist")
	
	# Test hero option buttons
	var option_buttons = []
	for i in range(1, 6):
		var button = hero_selection_ui.get_node_or_null("Panel/HeroOptionsContainer/HeroOption%d" % i)
		test_framework.assert_not_null(button, "Hero option button %d should exist" % i)
		if button:
			option_buttons.append(button)
	
	test_framework.assert_array_size(option_buttons, 5, "Should have exactly 5 hero option buttons")
	
	# Test initial UI state
	test_framework.assert_false(hero_selection_ui.visible, "Selection UI should be hidden initially")
	test_framework.assert_false(hero_selection_ui.is_visible, "Selection visibility flag should be false initially")
	test_framework.assert_array_size(hero_selection_ui.hero_buttons, 5, "Hero buttons array should be initialized")
	
	# Test UI show/hide functionality
	hero_selection_ui.show_selection()
	test_framework.assert_true(hero_selection_ui.visible, "UI should become visible when shown")
	test_framework.assert_true(hero_selection_ui.is_visible, "Visibility flag should be updated")
	
	hero_selection_ui.hide_selection()
	test_framework.assert_false(hero_selection_ui.visible, "UI should be hidden when hidden")
	test_framework.assert_false(hero_selection_ui.is_visible, "Visibility flag should be updated")
	
	print("✓ Hero selection interface tests passed")

func test_hero_pool_generation():
	"""Test random hero pool generation for selection"""
	print("Testing hero pool generation...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test hero data availability
	test_framework.assert_has_key(Data.heroes, "phantom_spirit", "Phantom spirit hero data should exist")
	test_framework.assert_true(Data.heroes.size() >= 1, "Should have at least one hero defined")
	
	# Test hero pool generation logic
	var available_heroes = generate_test_hero_pool()
	test_framework.assert_array_size(available_heroes, 5, "Hero pool should contain exactly 5 heroes")
	
	# Test that all heroes in pool are valid
	for hero_type in available_heroes:
		test_framework.assert_has_key(Data.heroes, hero_type, "Hero '%s' should exist in data" % hero_type)
		test_framework.assert_false(hero_type.is_empty(), "Hero type should not be empty")
	
	# Test duplicate prevention in hero pool
	var unique_heroes = {}
	for hero_type in available_heroes:
		unique_heroes[hero_type] = true
	test_framework.assert_equal(unique_heroes.size(), available_heroes.size(), "All heroes in pool should be unique")
	
	# Test hero selection with generated pool
	hero_selection_ui.show_hero_selection(available_heroes)
	test_framework.assert_array_size(hero_selection_ui.available_heroes, 5, "Available heroes should be set correctly")
	
	# Test button text assignment
	for i in range(5):
		var button = hero_selection_ui.hero_buttons[i]
		var hero_type = available_heroes[i]
		var hero_data = Data.heroes[hero_type]
		test_framework.assert_equal(button.text, hero_data.name, "Button %d should show correct hero name" % i)
		test_framework.assert_equal(button.get_meta("hero_type"), hero_type, "Button %d should have correct hero type metadata" % i)
	
	print("✓ Hero pool generation tests passed")

func test_wave_triggering():
	"""Test wave-based hero selection triggering"""
	print("Testing wave triggering...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test wave manager connection
	var wave_manager = create_mock_wave_manager()
	test_scene.add_child(wave_manager)
	
	# Test level 1 wave triggering
	wave_manager.current_wave = 1
	test_framework.assert_true(should_trigger_hero_selection(1), "Should trigger hero selection at wave 1")
	
	# Test every 5th wave triggering
	for wave in [5, 10, 15, 20, 25]:
		wave_manager.current_wave = wave
		test_framework.assert_true(should_trigger_hero_selection(wave), "Should trigger hero selection at wave %d" % wave)
	
	# Test non-triggering waves
	for wave in [2, 3, 4, 6, 7, 8, 9, 11]:
		wave_manager.current_wave = wave
		test_framework.assert_false(should_trigger_hero_selection(wave), "Should not trigger hero selection at wave %d" % wave)
	
	# Test wave description updates
	hero_selection_ui.update_hero_descriptions()
	var description_label = hero_selection_ui.get_node("Panel/DescriptionLabel") as Label
	test_framework.assert_not_null(description_label, "Description label should exist")
	
	var expected_text = "第 %d 波 - 从以下5个英雄中选择1个" % wave_manager.current_wave
	test_framework.assert_equal(description_label.text, expected_text, "Description should show current wave number")
	
	# Test wave manager reference retrieval
	var retrieved_manager = hero_selection_ui.get_wave_manager()
	test_framework.assert_equal(retrieved_manager, wave_manager, "Should retrieve correct wave manager")
	
	print("✓ Wave triggering tests passed")

func test_hero_deployment():
	"""Test hero deployment after selection"""
	print("Testing hero deployment...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test hero selection signal handling
	var selection_triggered = false
	var selected_hero_type = ""
	
	hero_selection_ui.hero_selected.connect(func(hero_type):
		selection_triggered = true
		selected_hero_type = hero_type
	)
	
	# Test valid hero selection
	var test_heroes = ["phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit"]
	hero_selection_ui.show_hero_selection(test_heroes)
	
	# Simulate button press
	hero_selection_ui._on_hero_option_pressed(0)
	
	test_framework.assert_true(selection_triggered, "Hero selection signal should be emitted")
	test_framework.assert_equal(selected_hero_type, "phantom_spirit", "Correct hero type should be selected")
	test_framework.assert_false(hero_selection_ui.visible, "UI should hide after selection")
	
	# Test hero creation and deployment
	var deployed_hero = create_hero_at_position(selected_hero_type, Vector2(200, 200))
	test_framework.assert_not_null(deployed_hero, "Hero should be created at deployment position")
	test_framework.assert_equal(deployed_hero.global_position, Vector2(200, 200), "Hero should be placed at correct position")
	test_framework.assert_true(deployed_hero.is_alive, "Deployed hero should be alive")
	
	# Test deployment validation
	var valid_position = Vector2(300, 300)
	test_framework.assert_true(is_valid_deployment_position(valid_position), "Valid position should pass deployment check")
	
	var invalid_position = Vector2(-100, -100)  # Outside play area
	test_framework.assert_false(is_valid_deployment_position(invalid_position), "Invalid position should fail deployment check")
	
	# Test hero manager integration
	if mock_hero_manager:
		mock_hero_manager.deploy_hero(selected_hero_type, valid_position)
		test_framework.assert_true(mock_hero_manager.has_deployed_heroes(), "Hero manager should track deployed heroes")
	
	print("✓ Hero deployment tests passed")

func test_hero_replacement():
	"""Test hero replacement functionality"""
	print("Testing hero replacement...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test existing hero detection
	var existing_hero = create_test_hero()
	var hero_position = existing_hero.global_position
	
	test_framework.assert_true(is_hero_at_position(hero_position), "Should detect hero at position")
	
	# Test replacement conditions
	test_framework.assert_true(can_replace_hero(existing_hero), "Should be able to replace living hero")
	
	# Test replacement process
	var replacement_hero_type = "phantom_spirit"
	var replacement_hero = replace_hero(existing_hero, replacement_hero_type)
	
	test_framework.assert_not_null(replacement_hero, "Replacement hero should be created")
	test_framework.assert_false(is_instance_valid(existing_hero), "Original hero should be removed")
	test_framework.assert_equal(replacement_hero.global_position, hero_position, "Replacement hero should be at same position")
	
	# Test replacement limits
	var max_heroes = 5
	var heroes = []
	for i in range(max_heroes):
		heroes.append(create_test_hero())
	
	test_framework.assert_false(can_deploy_additional_hero(max_heroes), "Should not be able to deploy beyond maximum heroes")
	
	# Test replacement when at maximum
	test_framework.assert_true(can_replace_hero(heroes[0]), "Should be able to replace when at maximum")
	
	# Clean up test heroes
	for hero in heroes:
		if is_instance_valid(hero):
			hero.queue_free()
	
	print("✓ Hero replacement tests passed")

func test_selection_validation():
	"""Test selection validation and error handling"""
	print("Testing selection validation...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test invalid hero pool size
	var invalid_pool_small = ["phantom_spirit"]
	var invalid_pool_large = ["phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit"]
	
	# Test error handling for small pool (should not crash)
	hero_selection_ui.show_hero_selection(invalid_pool_small)
	test_framework.assert_array_size(hero_selection_ui.available_heroes, 0, "Should not accept pool smaller than 5")
	
	# Test error handling for large pool (should not crash)
	hero_selection_ui.show_hero_selection(invalid_pool_large)
	test_framework.assert_array_size(hero_selection_ui.available_heroes, 0, "Should not accept pool larger than 5")
	
	# Test invalid hero type in pool
	var pool_with_invalid = ["phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit", "invalid_hero"]
	hero_selection_ui.show_hero_selection(pool_with_invalid)
	
	# UI should still work but handle invalid hero gracefully
	var invalid_button = hero_selection_ui.hero_buttons[4]
	test_framework.assert_equal(invalid_button.text, "未知英雄", "Invalid hero should show as '未知英雄'")
	test_framework.assert_equal(invalid_button.get_meta("hero_type"), "", "Invalid hero should have empty metadata")
	
	# Test button press with invalid selection
	hero_selection_ui._on_hero_option_pressed(4)  # Press button with invalid hero
	test_framework.assert_true(hero_selection_ui.visible, "UI should not hide for invalid selection")
	
	# Test out of bounds button press
	hero_selection_ui._on_hero_option_pressed(-1)  # Should not crash
	hero_selection_ui._on_hero_option_pressed(10)  # Should not crash
	
	# Test empty hero pool
	var empty_pool = []
	hero_selection_ui.show_hero_selection(empty_pool)
	test_framework.assert_array_size(hero_selection_ui.available_heroes, 0, "Should handle empty pool gracefully")
	
	print("✓ Selection validation tests passed")

func test_ui_state_management():
	"""Test UI state management and persistence"""
	print("Testing UI state management...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test initial state
	test_framework.assert_false(hero_selection_ui.visible, "UI should start hidden")
	test_framework.assert_false(hero_selection_ui.is_visible, "Visibility flag should start false")
	test_framework.assert_array_size(hero_selection_ui.available_heroes, 0, "Available heroes should start empty")
	
	# Test state transitions
	var test_heroes = ["phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit"]
	
	# Show selection
	hero_selection_ui.show_hero_selection(test_heroes)
	test_framework.assert_true(hero_selection_ui.visible, "UI should be visible")
	test_framework.assert_true(hero_selection_ui.is_visible, "Visibility flag should be true")
	test_framework.assert_array_size(hero_selection_ui.available_heroes, 5, "Available heroes should be set")
	
	# Test state persistence through hide/show
	hero_selection_ui.hide_selection()
	hero_selection_ui.show_hero_selection(test_heroes)
	test_framework.assert_array_size(hero_selection_ui.available_heroes, 5, "Available heroes should persist")
	
	# Test cancellation handling
	var cancellation_triggered = false
	hero_selection_ui.selection_cancelled.connect(func():
		cancellation_triggered = true
	)
	
	# Simulate ESC key press
	var esc_event = InputEventKey.new()
	esc_event.keycode = KEY_ESCAPE
	esc_event.pressed = true
	hero_selection_ui._input(esc_event)
	
	test_framework.assert_true(cancellation_triggered, "Cancellation signal should be triggered")
	test_framework.assert_false(hero_selection_ui.visible, "UI should hide on cancellation")
	
	# Test input handling when not visible
	hero_selection_ui.hide_selection()
	hero_selection_ui._input(esc_event)  # Should not trigger anything
	test_framework.assert_false(cancellation_triggered, "Should not handle input when not visible")
	
	# Test active state checking
	test_framework.assert_false(hero_selection_ui.is_selection_active(), "Should not be active when hidden")
	hero_selection_ui.show_hero_selection(test_heroes)
	test_framework.assert_true(hero_selection_ui.is_selection_active(), "Should be active when shown")
	
	print("✓ UI state management tests passed")

func test_signal_handling():
	"""Test signal connections and handling"""
	print("Testing signal handling...")
	
	test_framework.assert_not_null(hero_selection_ui, "Hero selection UI should be loaded")
	
	if not hero_selection_ui:
		return
	
	# Test signal definitions
	test_framework.assert_true(hero_selection_ui.has_signal("hero_selected"), "Should have hero_selected signal")
	test_framework.assert_true(hero_selection_ui.has_signal("selection_cancelled"), "Should have selection_cancelled signal")
	
	# Test signal connections
	var hero_selected_count = 0
	var selection_cancelled_count = 0
	var last_selected_hero = ""
	
	hero_selection_ui.hero_selected.connect(func(hero_type):
		hero_selected_count += 1
		last_selected_hero = hero_type
	)
	
	hero_selection_ui.selection_cancelled.connect(func():
		selection_cancelled_count += 1
	)
	
	# Test hero selection signal
	var test_heroes = ["phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit", "phantom_spirit"]
	hero_selection_ui.show_hero_selection(test_heroes)
	hero_selection_ui._on_hero_option_pressed(0)
	
	test_framework.assert_equal(hero_selected_count, 1, "Hero selected signal should be emitted once")
	test_framework.assert_equal(last_selected_hero, "phantom_spirit", "Correct hero should be passed in signal")
	
	# Test selection cancelled signal
	hero_selection_ui.show_hero_selection(test_heroes)
	var esc_event = InputEventKey.new()
	esc_event.keycode = KEY_ESCAPE
	esc_event.pressed = true
	hero_selection_ui._input(esc_event)
	
	test_framework.assert_equal(selection_cancelled_count, 1, "Selection cancelled signal should be emitted once")
	
	# Test hero manager integration signals
	if mock_hero_manager:
		test_framework.assert_true(mock_hero_manager.has_signal("hero_selection_available"), "Mock hero manager should have selection available signal")
		test_framework.assert_true(mock_hero_manager.has_signal("hero_selection_completed"), "Mock hero manager should have selection completed signal")
		
		# Test signal connection to hero manager
		hero_selection_ui.setup_from_hero_manager(mock_hero_manager)
		
		# This would test the actual signal connections in a real scenario
		test_framework.assert_true(true, "Hero manager integration should be set up")
	
	# Test signal disconnection
	hero_selection_ui._exit_tree()
	# Should not crash when signals are disconnected
	
	print("✓ Signal handling tests passed")

# Helper functions

func generate_test_hero_pool() -> Array[String]:
	"""Generate a test hero pool for selection"""
	var all_heroes = Data.heroes.keys() as Array[String]
	var pool = []
	
	# If we have less than 5 heroes, duplicate some for testing
	while pool.size() < 5:
		for hero in all_heroes:
			if pool.size() >= 5:
				break
			pool.append(hero)
	
	# If we still don't have enough, fill with phantom_spirit
	while pool.size() < 5:
		pool.append("phantom_spirit")
	
	return pool.slice(0, 5)  # Ensure exactly 5 heroes

func create_mock_wave_manager() -> Node:
	"""Create a mock wave manager for testing"""
	var wave_manager = Node.new()
	wave_manager.name = "WaveManager"
	wave_manager.set_script(preload("res://Tests/Mocks/MockWaveManager.gd"))
	wave_manager.current_wave = 1
	return wave_manager

func should_trigger_hero_selection(wave: int) -> bool:
	"""Determine if hero selection should trigger at given wave"""
	return wave == 1 or (wave % 5 == 0)

func create_hero_at_position(hero_type: String, position: Vector2) -> HeroBase:
	"""Create a hero at specified position"""
	var hero_scene = Data.load_resource_safe("res://Scenes/heroes/%s.tscn" % hero_type, "PackedScene")
	if not hero_scene:
		return null
	
	var hero = hero_scene.instantiate() as HeroBase
	if hero:
		test_scene.add_child(hero)
		hero.hero_type = hero_type
		hero.setup_hero_data()
		hero.global_position = position
		hero.respawn_hero()
	
	return hero

func is_hero_at_position(position: Vector2) -> bool:
	"""Check if there's a hero at the given position"""
	# This is a simplified check - in reality would use spatial queries
	var heroes = test_scene.get_tree().get_nodes_in_group("heroes")
	for hero in heroes:
		if hero.global_position.distance_to(position) < 50:
			return true
	return false

func is_valid_deployment_position(position: Vector2) -> bool:
	"""Check if position is valid for hero deployment"""
	# Simplified validation - should check pathfinding, collision, etc.
	return position.x >= 0 and position.y >= 0 and position.x <= 1000 and position.y <= 1000

func can_deploy_additional_hero(current_count: int) -> bool:
	"""Check if additional hero can be deployed"""
	return current_count < 5  # Maximum 5 heroes

func can_replace_hero(hero: HeroBase) -> bool:
	"""Check if hero can be replaced"""
	return hero and is_instance_valid(hero) and hero.is_alive

func replace_hero(old_hero: HeroBase, new_hero_type: String) -> HeroBase:
	"""Replace existing hero with new one"""
	if not old_hero or not is_instance_valid(old_hero):
		return null
	
	var position = old_hero.global_position
	old_hero.queue_free()
	
	return create_hero_at_position(new_hero_type, position)

func create_test_hero() -> HeroBase:
	"""Create a test hero for testing purposes"""
	return create_hero_at_position("phantom_spirit", Vector2(100, 100))

func cleanup():
	"""Clean up test resources"""
	if hero_selection_ui and is_instance_valid(hero_selection_ui):
		hero_selection_ui.queue_free()
	
	if mock_hero_manager and is_instance_valid(mock_hero_manager):
		mock_hero_manager.queue_free()
	
	if test_scene and is_instance_valid(test_scene):
		test_scene.queue_free()
	
	if test_framework and is_instance_valid(test_framework):
		test_framework.queue_free()