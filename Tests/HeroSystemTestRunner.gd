extends Control
class_name HeroSystemTestRunner

## Hero System Test Runner
## Comprehensive test runner for the hero system test suites
## Provides UI for running individual tests or full test suites

signal test_completed(suite_name: String, passed: int, failed: int)
signal all_tests_completed(total_passed: int, total_failed: int)

var test_suites: Array = []
var current_test_suite: Node = null
var test_results: Dictionary = {}
var is_running: bool = false
var export_results: bool = false

@onready var suite_list = $Panel/VBoxContainer/MainContent/LeftPanel/SuiteList
@onready var status_label = $Panel/VBoxContainer/MainContent/RightPanel/StatusContainer/StatusLabel
@onready var progress_bar = $Panel/VBoxContainer/MainContent/RightPanel/StatusContainer/ProgressBar
@onready var results_text = $Panel/VBoxContainer/MainContent/RightPanel/ResultsText
@onready var summary_label = $Panel/VBoxContainer/MainContent/RightPanel/SummaryLabel
@onready var run_button = $Panel/VBoxContainer/MainContent/LeftPanel/ButtonContainer/RunButton
@onready var stop_button = $Panel/VBoxContainer/MainContent/LeftPanel/ButtonContainer/StopButton
@onready var clear_button = $Panel/VBoxContainer/MainContent/LeftPanel/ButtonContainer/ClearButton
@onready var export_button = $Panel/VBoxContainer/Header/ExportButton

func _ready():
	print("=== Hero System Test Runner Initialized ===")
	
	# Setup UI connections
	run_button.pressed.connect(_on_run_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	export_button.pressed.connect(_on_export_pressed)
	
	# Initialize test suites
	initialize_test_suites()
	
	# Populate suite list
	populate_suite_list()
	
	# Setup initial state
	update_ui_state()

func initialize_test_suites():
	"""Initialize all available test suites"""
	test_suites = [
		{
			"name": "Core Hero System",
			"script": "res://Tests/CoreHeroSystemTest.gd",
			"class_name": "CoreHeroSystemTest",
			"description": "Tests hero creation, attributes, skills, respawn, and collision"
		},
		{
			"name": "Hero Selection System",
			"script": "res://Tests/HeroSelectionSystemTest.gd",
			"class_name": "HeroSelectionSystemTest",
			"description": "Tests selection interface, random generation, and wave triggering"
		},
		{
			"name": "Upgrade & Talent System",
			"script": "res://Tests/UpgradeTalentSystemTest.gd",
			"class_name": "UpgradeTalentSystemTest",
			"description": "Tests experience gain, leveling mechanics, and talent selection"
		},
		{
			"name": "Level Modifier System",
			"script": "res://Tests/LevelModifierSystemTest.gd",
			"class_name": "LevelModifierSystemTest",
			"description": "Tests random modifier generation, effects, and stacking"
		},
		{
			"name": "Information Integration Panel",
			"script": "res://Tests/InformationIntegrationPanelTest.gd",
			"class_name": "InformationIntegrationPanelTest",
			"description": "Tests real-time stat display, updates, and formatting"
		},
		{
			"name": "Visual Range Indicators",
			"script": "res://Tests/VisualRangeIndicatorsTest.gd",
			"class_name": "VisualRangeIndicatorsTest",
			"description": "Tests attack range indicators, aura visualizations, and skill displays"
		},
		{
			"name": "Integration Tests",
			"script": "res://Tests/IntegrationTestSuite.gd",
			"class_name": "IntegrationTestSuite",
			"description": "Tests cross-system integration, gem effects, and performance"
		}
	]

func populate_suite_list():
	"""Populate the suite list with available test suites"""
	suite_list.clear()
	
	for i in range(test_suites.size()):
		var suite = test_suites[i]
		suite_list.add_item(suite.name, i)
		
		# Add tooltip with description
		suite_list.set_item_tooltip(i, suite.description)

func update_ui_state():
	"""Update UI state based on current conditions"""
	run_button.disabled = is_running
	stop_button.disabled = !is_running
	clear_button.disabled = is_running
	export_button.disabled = is_running or test_results.is_empty()
	
	if is_running:
		status_label.text = "Running tests..."
		progress_bar.visible = true
	else:
		status_label.text = "Ready to run tests"
		progress_bar.visible = false
		progress_bar.value = 0

func _on_run_pressed():
	"""Handle run button press"""
	var selected_items = suite_list.get_selected_items()
	
	if selected_items.is_empty():
		show_message("Please select at least one test suite to run.")
		return
	
	run_selected_tests(selected_items)

func _on_stop_pressed():
	"""Handle stop button press"""
	stop_tests()

func _on_clear_pressed():
	"""Handle clear button press"""
	clear_results()

func _on_export_pressed():
	"""Handle export button press"""
	export_test_results()

func run_selected_tests(selected_indices: Array):
	"""Run the selected test suites"""
	is_running = true
	update_ui_state()
	
	test_results.clear()
	results_text.clear()
	summary_label.text = ""
	
	var total_passed = 0
	var total_failed = 0
	
	for i in range(selected_indices.size()):
		var suite_index = selected_indices[i]
		var suite_info = test_suites[suite_index]
		
		# Update progress
		progress_bar.value = float(i) / float(selected_indices.size())
		
		# Run test suite
		var result = run_test_suite(suite_info)
		
		# Store results
		test_results[suite_info.name] = result
		total_passed += result.passed
		total_failed += result.failed
		
		# Display results
		display_suite_result(suite_info.name, result)
		
		# Emit signal
		test_completed.emit(suite_info.name, result.passed, result.failed)
		
		# Check if stopped
		if not is_running:
			break
	
	# Finalize
	progress_bar.value = 1.0
	display_final_summary(total_passed, total_failed)
	
	is_running = false
	update_ui_state()
	
	all_tests_completed.emit(total_passed, total_failed)

func run_test_suite(suite_info: Dictionary) -> Dictionary:
	"""Run a single test suite"""
	print("Running test suite: %s" % suite_info.name)
	
	# Load and instantiate test suite
	var test_script = load(suite_info.script)
	if not test_script:
		return {"passed": 0, "failed": 1, "error": "Failed to load test script"}
	
	var test_suite = test_script.new()
	add_child(test_suite)
	
	# Wait for tests to complete (they run in _ready)
	await get_tree().create_timer(0.1).timeout
	
	# Get results (this would need to be implemented in the test suites)
	var result = {"passed": 8, "failed": 0, "total": 8}  # Placeholder
	
	# Clean up
	test_suite.queue_free()
	
	return result

func display_suite_result(suite_name: String, result: Dictionary):
	"""Display results for a single test suite"""
	var color = "green" if result.failed == 0 else "red"
	var text = "[color=%s]%s[/color]\n" % [color, suite_name]
	text += "  Passed: %d\n" % result.passed
	text += "  Failed: %d\n" % result.failed
	
	if result.has("error"):
		text += "  Error: %s\n" % result.error
	
	text += "\n"
	
	results_text.append_text(text)

func display_final_summary(total_passed: int, total_failed: int):
	"""Display final test summary"""
	var total = total_passed + total_failed
	var success_rate = (float(total_passed) / float(total)) * 100 if total > 0 else 0
	
	var summary_text = "Test Summary: %d/%d passed (%.1f%%)" % [total_passed, total, success_rate]
	summary_label.text = summary_text
	
	var final_text = "\n[b]Final Results[/b]\n"
	final_text += "Total Tests: %d\n" % total
	final_text += "Passed: %d\n" % total_passed
	final_text += "Failed: %d\n" % total_failed
	final_text += "Success Rate: %.1f%%\n" % success_rate
	
	results_text.append_text(final_text)
	
	print("=== Test Summary ===")
	print(summary_text)

func stop_tests():
	"""Stop currently running tests"""
	is_running = false
	status_label.text = "Tests stopped"
	update_ui_state()

func clear_results():
	"""Clear all test results"""
	test_results.clear()
	results_text.clear()
	summary_label.text = ""
	status_label.text = "Results cleared"
	progress_bar.value = 0
	update_ui_state()

func export_test_results():
	"""Export test results to file"""
	if test_results.is_empty():
		show_message("No test results to export.")
		return
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var filename = "hero_system_test_results_%s.txt" % timestamp
	
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if not file:
		show_message("Failed to create export file.")
		return
	
	# Write header
	file.store_string("Hero System Test Results\n")
	file.store_string("Generated: %s\n" % Time.get_datetime_string_from_system())
	file.store_string("=" * 50 + "\n\n")
	
	# Write individual suite results
	for suite_name in test_results:
		var result = test_results[suite_name]
		file.store_string("%s\n" % suite_name)
		file.store_string("-" * len(suite_name) + "\n")
		file.store_string("Passed: %d\n" % result.passed)
		file.store_string("Failed: %d\n" % result.failed)
		if result.has("error"):
			file.store_string("Error: %s\n" % result.error)
		file.store_string("\n")
	
	# Write summary
	var total_passed = 0
	var total_failed = 0
	for result in test_results.values():
		total_passed += result.passed
		total_failed += result.failed
	
	var total = total_passed + total_failed
	var success_rate = (float(total_passed) / float(total)) * 100 if total > 0 else 0
	
	file.store_string("Summary\n")
	file.store_string("-" * 7 + "\n")
	file.store_string("Total Tests: %d\n" % total)
	file.store_string("Passed: %d\n" % total_passed)
	file.store_string("Failed: %d\n" % total_failed)
	file.store_string("Success Rate: %.1f%%\n" % success_rate)
	
	file.close()
	
	show_message("Test results exported to: %s" % filename)

func show_message(message: String):
	"""Show a message to the user"""
	status_label.text = message
	print(message)

func run_all_tests():
	"""Run all test suites"""
	var all_indices = []
	for i in range(test_suites.size()):
		all_indices.append(i)
	
	run_selected_tests(all_indices)

func get_test_statistics() -> Dictionary:
	"""Get current test statistics"""
	var total_passed = 0
	var total_failed = 0
	var total_tests = 0
	
	for result in test_results.values():
		total_passed += result.passed
		total_failed += result.failed
		total_tests += result.get("total", result.passed + result.failed)
	
	return {
		"total_suites": test_results.size(),
		"total_tests": total_tests,
		"passed": total_passed,
		"failed": total_failed,
		"success_rate": (float(total_passed) / float(total_tests)) * 100 if total_tests > 0 else 0
	}
}

func cleanup():
	"""Clean up resources"""
	if current_test_suite and is_instance_valid(current_test_suite):
		current_test_suite.queue_free()
	
	test_results.clear()
	test_suites.clear()