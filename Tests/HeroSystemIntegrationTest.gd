extends Control

## Hero System Integration Test
## Tests all hero system components and their integration

@onready var test_log = $TestLog
@onready var run_button = $RunTestButton
@onready var status_label = $StatusLabel

var test_results = []
var current_test_index = 0

func _ready() -> void:
	# Setup UI
	run_button.pressed.connect(run_all_tests)
	status_label.text = "Ready to test"
	test_log.text = "Click 'Run Tests' to start hero system testing"

func run_all_tests() -> void:
	"""Run all hero system tests"""
	status_label.text = "Running tests..."
	test_log.text = ""
	test_results.clear()
	current_test_index = 0
	
	# Disable button during tests
	run_button.disabled = true
	
	# Run tests sequentially
	call_deferred("run_next_test")

func run_next_test() -> void:
	"""Run the next test in sequence"""
	var tests = [
		"test_data_availability",
		"test_class_instantiation", 
		"test_ui_components",
		"test_manager_systems",
		"test_hero_creation",
		"test_signal_connections",
		"test_integration_workflow"
	]
	
	if current_test_index >= tests.size():
		# All tests completed
		show_test_results()
		run_button.disabled = false
		return
	
	var test_name = tests[current_test_index]
	current_test_index += 1
	
	# Run the test
	if has_method(test_name):
		call(test_name)
	else:
		log_test_result(test_name, false, "Test method not found")
	
	# Schedule next test
	call_deferred("run_next_test")

func log_test_result(test_name: String, passed: bool, message: String = "") -> void:
	"""Log test result"""
	var result = {
		"test": test_name,
		"passed": passed,
		"message": message
	}
	test_results.append(result)
	
	var status_icon = "✓" if passed else "✗"
	var log_entry = "%s %s: %s\n" % [status_icon, test_name, message]
	test_log.text += log_entry

func show_test_results() -> void:
	"""Show final test results"""
	var passed_count = 0
	for result in test_results:
		if result.passed:
			passed_count += 1
	
	var total_count = test_results.size()
	var success_rate = float(passed_count) / total_count * 100 if total_count > 0 else 0
	
	status_label.text = "Tests completed: %d/%d (%.1f%%)" % [passed_count, total_count, success_rate]
	
	if success_rate >= 90:
		status_label.modulate = Color.GREEN
	elif success_rate >= 70:
		status_label.modulate = Color.YELLOW
	else:
		status_label.modulate = Color.RED

func test_data_availability() -> void:
	"""Test if all required hero data is available"""
	var passed = true
	var message = ""
	
	# Test hero data
	if not Data.heroes:
		passed = false
		message += "Hero data missing. "
	else:
		message += "Found %d heroes. " % Data.heroes.size()
	
	# Test phantom_spirit specifically
	if not Data.heroes.has("phantom_spirit"):
		passed = false
		message += "Phantom Spirit hero missing. "
	
	# Test hero skills
	if not Data.hero_skills:
		passed = false
		message += "Hero skills missing. "
	else:
		message += "Found %d skills. " % Data.hero_skills.size()
	
	# Test hero talents
	if not Data.hero_talents:
		passed = false
		message += "Hero talents missing. "
	
	# Test level modifiers
	if not Data.level_modifiers:
		passed = false
		message += "Level modifiers missing. "
	
	log_test_result("Data Availability", passed, message)

func test_class_instantiation() -> void:
	"""Test if hero classes can be instantiated"""
	var passed = true
	var message = ""
	
	# Test HeroBase
	var hero_base = HeroBase.new()
	if hero_base:
		message += "HeroBase OK. "
		hero_base.queue_free()
	else:
		passed = false
		message += "HeroBase failed. "
	
	# Test HeroSkill
	var hero_skill = HeroSkill.new()
	if hero_skill:
		message += "HeroSkill OK. "
		hero_skill.queue_free()
	else:
		passed = false
		message += "HeroSkill failed. "
	
	log_test_result("Class Instantiation", passed, message)

func test_ui_components() -> void:
	"""Test if UI components are available"""
	var passed = true
	var message = ""
	
	# Get main scene
	var tree = get_tree()
	if not tree or not tree.current_scene:
		passed = false
		message += "Cannot access scene tree. "
		log_test_result("UI Components", passed, message)
		return
	
	var main = tree.current_scene.get_node_or_null("Main") as Node2D
	if not main:
		passed = false
		message += "Main scene not found. "
		log_test_result("UI Components", passed, message)
		return
	
	# Test HeroSelection UI
	var hero_selection = main.get_node_or_null("UI/HeroSelection") as Control
	if hero_selection:
		message += "HeroSelection OK. "
	else:
		passed = false
		message += "HeroSelection missing. "
	
	# Test HeroInfoPanel UI
	var hero_info_panel = main.get_node_or_null("UI/HeroInfoPanel") as Control
	if hero_info_panel:
		message += "HeroInfoPanel OK. "
	else:
		passed = false
		message += "HeroInfoPanel missing. "
	
	# Test HeroTalentSelection UI
	var talent_selection = main.get_node_or_null("UI/HeroTalentSelection") as Control
	if talent_selection:
		message += "HeroTalentSelection OK. "
	else:
		passed = false
		message += "HeroTalentSelection missing. "
	
	log_test_result("UI Components", passed, message)

func test_manager_systems() -> void:
	"""Test if manager systems are available"""
	var passed = true
	var message = ""
	
	# Get main scene
	var tree = get_tree()
	if not tree or not tree.current_scene:
		passed = false
		message += "Cannot access scene tree. "
		log_test_result("Manager Systems", passed, message)
		return
	
	var main = tree.current_scene.get_node_or_null("Main") as Node2D
	if not main:
		passed = false
		message += "Main scene not found. "
		log_test_result("Manager Systems", passed, message)
		return
	
	# Test HeroManager
	var hero_manager = main.get_node_or_null("HeroManager") as HeroManager
	if hero_manager:
		message += "HeroManager OK. "
	else:
		passed = false
		message += "HeroManager missing. "
	
	# Test HeroTalentSystem
	var talent_system = main.get_node_or_null("HeroTalentSystem") as HeroTalentSystem
	if talent_system:
		message += "HeroTalentSystem OK. "
	else:
		passed = false
		message += "HeroTalentSystem missing. "
	
	# Test LevelModifierSystem
	var modifier_system = main.get_node_or_null("LevelModifierSystem") as LevelModifierSystem
	if modifier_system:
		message += "LevelModifierSystem OK. "
	else:
		passed = false
		message += "LevelModifierSystem missing. "
	
	# Test HeroRangeIndicator
	var range_indicator = main.get_node_or_null("HeroRangeIndicator") as HeroRangeIndicator
	if range_indicator:
		message += "HeroRangeIndicator OK. "
	else:
		passed = false
		message += "HeroRangeIndicator missing. "
	
	log_test_result("Manager Systems", passed, message)

func test_hero_creation() -> void:
	"""Test hero creation and initialization"""
	var passed = true
	var message = ""
	
	# Try to create phantom_spirit hero
	var hero_scene = Data.load_resource_safe("res://Scenes/heroes/phantom_spirit.tscn", "PackedScene")
	if not hero_scene:
		passed = false
		message += "Cannot load phantom_spirit scene. "
		log_test_result("Hero Creation", passed, message)
		return
	
	var hero = hero_scene.instantiate() as HeroBase
	if not hero:
		passed = false
		message += "Cannot instantiate hero. "
		log_test_result("Hero Creation", passed, message)
		return
	
	# Test hero initialization
	hero.hero_type = "phantom_spirit"
	hero.setup_hero_data()
	
	if hero.hero_name == "幻影之灵":
		message += "Hero name OK. "
	else:
		passed = false
		message += "Hero name incorrect: %s. " % hero.hero_name
	
	# Test hero skills
	if hero.skills.size() == 3:
		message += "Skills loaded (%d). " % hero.skills.size()
	else:
		passed = false
		message += "Skills count incorrect: %d. " % hero.skills.size()
	
	# Test hero stats
	if hero.current_stats.has("max_hp") and hero.current_stats.has("damage"):
		message += "Stats loaded. "
	else:
		passed = false
		message += "Stats missing. "
	
	# Clean up
	hero.queue_free()
	
	log_test_result("Hero Creation", passed, message)

func test_signal_connections() -> void:
	"""Test if signals are properly connected"""
	var passed = true
	var message = ""
	
	# Get main scene
	var tree = get_tree()
	if not tree or not tree.current_scene:
		passed = false
		message += "Cannot access scene tree. "
		log_test_result("Signal Connections", passed, message)
		return
	
	var main = tree.current_scene.get_node_or_null("Main") as Node2D
	if not main:
		passed = false
		message += "Main scene not found. "
		log_test_result("Signal Connections", passed, message)
		return
	
	# Test HeroManager signals
	var hero_manager = main.get_node_or_null("HeroManager") as HeroManager
	if hero_manager:
		var signals = [
			"hero_deployed", "hero_died", "hero_respawned", "hero_leveled_up",
			"hero_selection_available", "hero_selection_completed", "hero_selection_started",
			"all_heroes_dead", "hero_experience_gained", "talent_selection_requested"
		]
		
		for signal_name in signals:
			if hero_manager.has_signal(signal_name):
				message += "%s OK. " % signal_name
			else:
				passed = false
				message += "%s missing. " % signal_name
	else:
		passed = false
		message += "HeroManager not found. "
	
	log_test_result("Signal Connections", passed, message)

func test_integration_workflow() -> void:
	"""Test basic integration workflow"""
	var passed = true
	var message = ""
	
	# Test if hero selection can be triggered
	var tree = get_tree()
	if not tree or not tree.current_scene:
		passed = false
		message += "Cannot access scene tree. "
		log_test_result("Integration Workflow", passed, message)
		return
	
	var main = tree.current_scene.get_node_or_null("Main") as Node2D
	if not main:
		passed = false
		message += "Main scene not found. "
		log_test_result("Integration Workflow", passed, message)
		return
	
	var hero_manager = main.get_node_or_null("HeroManager") as HeroManager
	if not hero_manager:
		passed = false
		message += "HeroManager not found. "
		log_test_result("Integration Workflow", passed, message)
		return
	
	# Test hero pool
	if hero_manager.available_hero_pool.size() > 0:
		message += "Hero pool OK (%d heroes). " % hero_manager.available_hero_pool.size()
	else:
		passed = false
		message += "Hero pool empty. "
	
	# Test deployment zones
	var deployment_zones = hero_manager.get_deployment_zones_data()
	if deployment_zones.size() > 0:
		message += "Deployment zones OK (%d zones). " % deployment_zones.size()
	else:
		passed = false
		message += "No deployment zones. "
	
	# Test talent system
	var talent_system = main.get_node_or_null("HeroTalentSystem") as HeroTalentSystem
	if talent_system:
		message += "TalentSystem accessible. "
	else:
		passed = false
		message += "TalentSystem not accessible. "
	
	log_test_result("Integration Workflow", passed, message)

func get_test_summary() -> Dictionary:
	"""Get test summary statistics"""
	var passed = 0
	var total = test_results.size()
	
	for result in test_results:
		if result.passed:
			passed += 1
	
	return {
		"total": total,
		"passed": passed,
		"failed": total - passed,
		"success_rate": float(passed) / total * 100 if total > 0 else 0
	}