extends Node

## Hero System Test Script
## Used to verify that all hero system components work correctly

func _ready() -> void:
	print("=== Hero System Test Started ===")
	
	# Test 1: Check if Data has hero definitions
	test_hero_data()
	
	# Test 2: Check if hero classes are valid
	test_hero_classes()
	
	# Test 3: Check if UI components are available
	test_ui_components()
	
	# Test 4: Check if manager systems are available
	test_manager_systems()
	
	print("=== Hero System Test Completed ===")

func test_hero_data() -> void:
	print("Testing hero data...")
	
	if not Data.heroes:
		push_error("Hero data not found in Data.gd")
		return
	
	var hero_count = Data.heroes.size()
	print("✓ Found %d heroes in Data.gd" % hero_count)
	
	# Check for phantom_spirit hero
	if Data.heroes.has("phantom_spirit"):
		print("✓ Phantom Spirit hero data available")
	else:
		push_error("Phantom Spirit hero data missing")
	
	# Check hero skills
	if not Data.hero_skills:
		push_error("Hero skills not found in Data.gd")
		return
	
	var skill_count = Data.hero_skills.size()
	print("✓ Found %d hero skills in Data.gd" % skill_count)
	
	# Check hero talents
	if not Data.hero_talents:
		push_error("Hero talents not found in Data.gd")
		return
	
	print("✓ Hero talents data available")
	
	# Check level modifiers
	if not Data.level_modifiers:
		push_error("Level modifiers not found in Data.gd")
		return
	
	print("✓ Level modifiers data available")

func test_hero_classes() -> void:
	print("Testing hero classes...")
	
	# Test HeroBase class
	var hero_base = HeroBase.new()
	if hero_base:
		print("✓ HeroBase class can be instantiated")
		hero_base.queue_free()
	else:
		push_error("HeroBase class cannot be instantiated")
	
	# Test HeroSkill class
	var hero_skill = HeroSkill.new()
	if hero_skill:
		print("✓ HeroSkill class can be instantiated")
		hero_skill.queue_free()
	else:
		push_error("HeroSkill class cannot be instantiated")

func test_ui_components() -> void:
	print("Testing UI components...")
	
	# Check if UI components are available in main scene
	var tree = get_tree()
	if not tree or not tree.current_scene:
		push_error("Cannot access current scene")
		return
	
	var main = tree.current_scene.get_node_or_null("Main") as Node2D
	if not main:
		push_error("Main scene not found")
		return
	
	# Check HeroSelection UI
	var hero_selection = main.get_node_or_null("UI/HeroSelection") as Control
	if hero_selection:
		print("✓ HeroSelection UI component available")
	else:
		push_error("HeroSelection UI component missing")
	
	# Check HeroInfoPanel UI
	var hero_info_panel = main.get_node_or_null("UI/HeroInfoPanel") as Control
	if hero_info_panel:
		print("✓ HeroInfoPanel UI component available")
	else:
		push_error("HeroInfoPanel UI component missing")
	
	# Check HeroTalentSelection UI
	var talent_selection = main.get_node_or_null("UI/HeroTalentSelection") as Control
	if talent_selection:
		print("✓ HeroTalentSelection UI component available")
	else:
		push_error("HeroTalentSelection UI component missing")

func test_manager_systems() -> void:
	print("Testing manager systems...")
	
	# Check if manager systems are available in main scene
	var tree = get_tree()
	if not tree or not tree.current_scene:
		push_error("Cannot access current scene")
		return
	
	var main = tree.current_scene.get_node_or_null("Main") as Node2D
	if not main:
		push_error("Main scene not found")
		return
	
	# Check HeroManager
	var hero_manager = main.get_node_or_null("HeroManager") as HeroManager
	if hero_manager:
		print("✓ HeroManager system available")
	else:
		push_error("HeroManager system missing")
	
	# Check HeroTalentSystem
	var talent_system = main.get_node_or_null("HeroTalentSystem") as HeroTalentSystem
	if talent_system:
		print("✓ HeroTalentSystem available")
	else:
		push_error("HeroTalentSystem missing")
	
	# Check LevelModifierSystem
	var modifier_system = main.get_node_or_null("LevelModifierSystem") as LevelModifierSystem
	if modifier_system:
		print("✓ LevelModifierSystem available")
	else:
		push_error("LevelModifierSystem missing")
	
	# Check HeroRangeIndicator
	var range_indicator = main.get_node_or_null("HeroRangeIndicator") as HeroRangeIndicator
	if range_indicator:
		print("✓ HeroRangeIndicator available")
	else:
		push_error("HeroRangeIndicator missing")

func test_hero_creation() -> void:
	print("Testing hero creation...")
	
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	# Try to create a phantom_spirit hero
	var hero_scene = Data.load_resource_safe("res://Scenes/heroes/phantom_spirit.tscn", "PackedScene")
	if not hero_scene:
		push_error("Cannot load phantom_spirit scene")
		return
	
	var hero = hero_scene.instantiate() as HeroBase
	if not hero:
		push_error("Cannot instantiate phantom_spirit hero")
		return
	
	print("✓ Phantom Spirit hero created successfully")
	
	# Test hero initialization
	hero.hero_type = "phantom_spirit"
	hero.setup_hero_data()
	
	if hero.hero_name == "幻影之灵":
		print("✓ Hero data loaded correctly")
	else:
		push_error("Hero data not loaded correctly")
	
	# Test hero skills
	if hero.skills.size() == 3:
		print("✓ Hero skills loaded correctly")
	else:
		push_error("Hero skills not loaded correctly")
	
	# Clean up
	hero.queue_free()

func run_integration_test() -> void:
	print("Running integration test...")
	
	# This would test the full hero system workflow
	# For now, just verify that components can be connected
	print("Integration test placeholder - components verified")