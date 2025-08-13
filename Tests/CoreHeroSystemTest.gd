extends Node
class_name CoreHeroSystemTest

## Core Hero System Test Suite
## Tests fundamental hero functionality including creation, attributes, skills, respawn, and collision

const TestFramework = preload("res://Tests/TestFramework.gd")

var test_framework: TestFramework
var test_scene: Node2D
var hero_scene: PackedScene
var test_hero: HeroBase

func _ready():
	print("=== Core Hero System Test Suite Started ===")
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# Setup test environment
	setup_test_environment()
	
	# Run all tests
	run_all_tests()
	
	print("=== Core Hero System Test Suite Completed ===")

func setup_test_environment():
	"""Create test scene and load hero resources"""
	# Create test scene
	test_scene = Node2D.new()
	add_child(test_scene)
	
	# Load hero scene
	hero_scene = Data.load_resource_safe("res://Scenes/heroes/phantom_spirit.tscn", "PackedScene")
	if not hero_scene:
		push_error("Failed to load phantom_spirit hero scene")
		return

func run_all_tests():
	"""Execute all core hero system tests"""
	var tests = [
		{"name": "Hero Creation and Initialization", "func": test_hero_creation},
		{"name": "Hero Attribute System", "func": test_hero_attributes},
		{"name": "Hero Skill System", "func": test_hero_skills},
		{"name": "Hero Auto-Respawn", "func": test_hero_respawn},
		{"name": "Hero Path-Blocking Collision", "func": test_hero_collision},
		{"name": "Hero Charge Generation", "func": test_charge_generation},
		{"name": "Hero Level Progression", "func": test_level_progression},
		{"name": "Hero Stat Calculations", "func": test_stat_calculations}
	]
	
	test_framework.run_test_suite("Core Hero System", tests)

func test_hero_creation():
	"""Test hero creation and basic initialization"""
	print("Testing hero creation...")
	
	# Test hero scene loading
	test_framework.assert_not_null(hero_scene, "Hero scene should load successfully")
	
	# Test hero instantiation
	test_hero = hero_scene.instantiate() as HeroBase
	test_framework.assert_not_null(test_hero, "Hero should instantiate successfully")
	
	if test_hero:
		test_scene.add_child(test_hero)
		
		# Test hero type assignment
		test_hero.hero_type = "phantom_spirit"
		test_framework.assert_equal(test_hero.hero_type, "phantom_spirit", "Hero type should be assigned correctly")
		
		# Test hero data setup
		test_hero.setup_hero_data()
		test_framework.assert_equal(test_hero.hero_name, "幻影之灵", "Hero name should be loaded from data")
		
		# Test hero skills loading
		test_framework.assert_array_size(test_hero.skills, 3, "Hero should have 3 skills loaded")
		
		# Test hero stats initialization
		test_framework.assert_has_key(test_hero.base_stats, "max_hp", "Hero should have max_hp stat")
		test_framework.assert_has_key(test_hero.base_stats, "damage", "Hero should have damage stat")
		test_framework.assert_has_key(test_hero.base_stats, "defense", "Hero should have defense stat")
		
		# Test current stats copy
		test_framework.assert_equal(test_hero.current_stats.max_hp, test_hero.base_stats.max_hp, "Current HP should match base HP")
		test_framework.assert_equal(test_hero.current_stats.damage, test_hero.base_stats.damage, "Current damage should match base damage")
		
		print("✓ Hero creation tests passed")

func test_hero_attributes():
	"""Test hero attribute system including HP, attack, defense, attack speed"""
	print("Testing hero attributes...")
	
	if not test_hero:
		test_hero = create_test_hero()
	
	# Test base attributes
	var expected_max_hp = 540
	var expected_damage = 58
	var expected_defense = 10
	var expected_attack_speed = 0.9
	var expected_attack_range = 150.0
	
	test_framework.assert_equal(test_hero.base_stats.max_hp, expected_max_hp, "Max HP should be 540")
	test_framework.assert_equal(test_hero.base_stats.damage, expected_damage, "Damage should be 58")
	test_framework.assert_equal(test_hero.base_stats.defense, expected_defense, "Defense should be 10")
	test_framework.assert_approximately(test_hero.base_stats.attack_speed, expected_attack_speed, 0.01, "Attack speed should be 0.9")
	test_framework.assert_equal(test_hero.base_stats.attack_range, expected_attack_range, "Attack range should be 150.0")
	
	# Test attribute modification
	test_hero.current_stats.damage = 100
	test_framework.assert_equal(test_hero.current_stats.damage, 100, "Damage should be modifiable")
	
	# Test health system
	test_framework.assert_true(test_hero.is_alive, "Hero should be alive initially")
	test_framework.assert_equal(test_hero.health_bar.value, expected_max_hp, "Health should be at maximum")
	
	# Test damage calculation
	var damage_taken = 50
	test_hero.take_damage(damage_taken)
	test_framework.assert_equal(test_hero.health_bar.value, expected_max_hp - damage_taken, "Health should decrease correctly")
	
	# Test death condition
	test_hero.take_damage(expected_max_hp)  # Take remaining health
	test_framework.assert_false(test_hero.is_alive, "Hero should die when health reaches 0")
	
	print("✓ Hero attribute tests passed")

func test_hero_skills():
	"""Test hero skill system including charging, casting, and cooldowns"""
	print("Testing hero skills...")
	
	if not test_hero:
		test_hero = create_test_hero()
	
	# Test skill initialization
	test_framework.assert_array_size(test_hero.skills, 3, "Hero should have 3 skills")
	
	# Test skill types and properties
	var skill_a = test_hero.skills[0]
	var skill_b = test_hero.skills[1]
	var skill_c = test_hero.skills[2]
	
	test_framework.assert_equal(skill_a.skill_type, "A", "First skill should be type A")
	test_framework.assert_equal(skill_b.skill_type, "B", "Second skill should be type B")
	test_framework.assert_equal(skill_c.skill_type, "C", "Third skill should be type C")
	
	# Test skill costs and cooldowns
	test_framework.assert_equal(skill_a.charge_cost, 20, "Skill A should cost 20 charge")
	test_framework.assert_equal(skill_b.charge_cost, 35, "Skill B should cost 35 charge")
	test_framework.assert_equal(skill_c.charge_cost, 60, "Skill C should cost 60 charge")
	
	test_framework.assert_equal(skill_a.cooldown, 5.0, "Skill A should have 5.0s cooldown")
	test_framework.assert_equal(skill_b.cooldown, 12.0, "Skill B should have 12.0s cooldown")
	test_framework.assert_equal(skill_c.cooldown, 90.0, "Skill C should have 90.0s cooldown")
	
	# Test charge system
	test_hero.current_charge = 0
	test_framework.assert_false(skill_a.can_cast(test_hero), "Should not be able to cast with insufficient charge")
	
	# Add sufficient charge
	test_hero.current_charge = 25
	test_framework.assert_true(skill_a.can_cast(test_hero), "Should be able to cast with sufficient charge")
	
	# Test skill casting
	test_hero.current_charge = 100
	var cast_success = skill_a.cast(test_hero, Vector2.ZERO)
	test_framework.assert_true(cast_success, "Skill casting should succeed")
	test_framework.assert_true(skill_a.is_on_cooldown, "Skill should be on cooldown after casting")
	test_framework.assert_false(skill_a.can_cast(test_hero), "Should not be able to cast while on cooldown")
	
	# Test cooldown reduction
	skill_a.cooldown_remaining = 2.0
	skill_a.reduce_cooldown(1.0)
	test_framework.assert_approximately(skill_a.cooldown_remaining, 1.0, 0.01, "Cooldown should reduce correctly")
	
	print("✓ Hero skill tests passed")

func test_hero_respawn():
	"""Test hero auto-respawn functionality"""
	print("Testing hero respawn...")
	
	if not test_hero:
		test_hero = create_test_hero()
	
	# Kill the hero
	test_hero.take_damage(test_hero.current_stats.max_hp)
	test_framework.assert_false(test_hero.is_alive, "Hero should be dead")
	test_framework.assert_true(test_hero.is_respawning, "Hero should be respawning")
	
	# Test respawn timer initialization
	test_framework.assert_true(test_hero.respawn_timer > 0, "Respawn timer should be initialized")
	
	# Simulate respawn process
	var respawn_time = test_hero.respawn_timer
	for i in range(int(respawn_time * 10) + 1):  # Simulate in 0.1s increments
		test_hero._process(0.1)
	
	test_framework.assert_true(test_hero.is_alive, "Hero should be alive after respawn")
	test_framework.assert_false(test_hero.is_respawning, "Hero should not be respawning after respawn")
	test_framework.assert_equal(test_hero.health_bar.value, test_hero.current_stats.max_hp, "Health should be restored after respawn")
	test_framework.assert_equal(test_hero.respawn_timer, 0.0, "Respawn timer should be reset")
	
	# Test multiple deaths and respawns
	test_hero.take_damage(test_hero.current_stats.max_hp)
	test_framework.assert_false(test_hero.is_alive, "Hero should die again")
	
	# Reset for next test
	test_hero.respawn_hero()
	test_framework.assert_true(test_hero.is_alive, "Hero should be alive after manual respawn")
	
	print("✓ Hero respawn tests passed")

func test_hero_collision():
	"""Test hero path-blocking collision system"""
	print("Testing hero collision...")
	
	if not test_hero:
		test_hero = create_test_hero()
	
	# Test collision shape setup
	test_framework.assert_not_null(test_hero.get_node_or_null("CollisionShape2D"), "Hero should have collision shape")
	
	var collision_shape = test_hero.get_node("CollisionShape2D") as CollisionShape2D
	test_framework.assert_not_null(collision_shape.shape, "Collision shape should have a shape defined")
	
	# Test collision layer
	test_framework.assert_true(test_hero.collision_layer > 0, "Hero should have collision layer set")
	test_framework.assert_true(test_hero.collision_mask > 0, "Hero should have collision mask set")
	
	# Test hero positioning and collision bounds
	var test_position = Vector2(100, 100)
	test_hero.global_position = test_position
	test_framework.assert_equal(test_hero.global_position, test_position, "Hero should move to specified position")
	
	# Test that hero blocks path (this would require enemy pathfinding simulation)
	# For now, we test the collision setup
	test_framework.assert_true(collision_shape.disabled == false, "Collision should be enabled for living hero")
	
	# Test collision disabling when dead
	test_hero.take_damage(test_hero.current_stats.max_hp)
	test_framework.assert_true(collision_shape.disabled, "Collision should be disabled when hero is dead")
	
	# Test collision re-enabling when respawned
	test_hero.respawn_hero()
	test_framework.assert_false(collision_shape.disabled, "Collision should be re-enabled when hero respawns")
	
	print("✓ Hero collision tests passed")

func test_charge_generation():
	"""Test hero charge generation mechanics"""
	print("Testing charge generation...")
	
	if not test_hero:
		test_hero = create_test_hero()
	
	# Test initial charge
	test_framework.assert_equal(test_hero.current_charge, 0, "Initial charge should be 0")
	test_framework.assert_equal(test_hero.max_charge, 100, "Max charge should be 100")
	
	# Test charge generation rate
	var charge_rate = test_hero.charge_generation
	test_framework.assert_equal(charge_rate, 2.0, "Charge generation rate should be 2.0 per second")
	
	# Simulate charge generation over time
	test_hero._process(1.0)  # 1 second
	test_framework.assert_approximately(test_hero.current_charge, charge_rate, 0.1, "Charge should generate after 1 second")
	
	test_hero._process(2.0)  # 2 more seconds (total 3 seconds)
	test_framework.assert_approximately(test_hero.current_charge, charge_rate * 3, 0.1, "Charge should accumulate over time")
	
	# Test charge cap
	test_hero.current_charge = test_hero.max_charge
	test_hero._process(1.0)  # Try to generate more charge
	test_framework.assert_equal(test_hero.current_charge, test_hero.max_charge, "Charge should not exceed maximum")
	
	# Test charge consumption
	test_hero.current_charge = 50
	var consumption = 20
	test_hero.consume_charge(consumption)
	test_framework.assert_equal(test_hero.current_charge, 30, "Charge should be consumed correctly")
	
	# Test insufficient charge consumption
	test_hero.current_charge = 10
	test_hero.consume_charge(consumption)
	test_framework.assert_equal(test_hero.current_charge, 10, "Charge should not go negative when insufficient")
	
	print("✓ Charge generation tests passed")

func test_level_progression():
	"""Test hero leveling and experience system"""
	print("Testing level progression...")
	
	if not test_hero:
		test_hero = create_test_hero()
	
	# Test initial level
	test_framework.assert_equal(test_hero.current_level, 1, "Initial level should be 1")
	test_framework.assert_equal(test_hero.experience, 0, "Initial experience should be 0")
	
	# Test experience gain
	var exp_gain = 100
	test_hero.gain_experience(exp_gain)
	test_framework.assert_equal(test_hero.experience, exp_gain, "Experience should increase correctly")
	
	# Test level up thresholds
	var level_2_exp = 300
	test_hero.experience = level_2_exp - 1
	test_framework.assert_equal(test_hero.current_level, 1, "Should not level up before threshold")
	
	test_hero.experience = level_2_exp
	test_hero.check_level_up()
	test_framework.assert_equal(test_hero.current_level, 2, "Should level up at threshold")
	test_framework.assert_true(test_hero.pending_talent_selection, "Should have pending talent selection at level 5")
	
	# Test stat growth with levels
	var base_damage = test_hero.base_stats.damage
	test_hero.current_level = 5
	test_hero.update_stats_for_level()
	test_framework.assert_true(test_hero.current_stats.damage > base_damage, "Stats should increase with level")
	
	# Test experience overflow handling
	test_hero.experience = 10000
	test_hero.check_level_up()
	test_framework.assert_true(test_hero.current_level >= 2, "Should handle experience overflow correctly")
	
	print("✓ Level progression tests passed")

func test_stat_calculations():
	"""Test hero stat calculations and modifiers"""
	print("Testing stat calculations...")
	
	if not test_hero:
		test_hero = create_test_hero()
	
	# Test base stats
	var base_damage = test_hero.base_stats.damage
	var base_defense = test_hero.base_stats.defense
	var base_attack_speed = test_hero.base_stats.attack_speed
	
	# Test stat modifications
	test_hero.apply_stat_modifier("damage", 1.5, "multiply")
	test_framework.assert_approximately(test_hero.current_stats.damage, base_damage * 1.5, 0.01, "Damage should be multiplied correctly")
	
	test_hero.apply_stat_modifier("defense", 5, "add")
	test_framework.assert_equal(test_hero.current_stats.defense, base_defense + 5, "Defense should be added correctly")
	
	# Test stat modifier stacking
	test_hero.apply_stat_modifier("damage", 1.2, "multiply")
	var expected_damage = base_damage * 1.5 * 1.2
	test_framework.assert_approximately(test_hero.current_stats.damage, expected_damage, 0.01, "Damage modifiers should stack multiplicatively")
	
	# Test stat modifier removal
	test_hero.remove_stat_modifier("defense", 5, "add")
	test_framework.assert_equal(test_hero.current_stats.defense, base_defense, "Defense should return to base after modifier removal")
	
	# Test attack speed calculations
	var attack_interval = 1.0 / base_attack_speed
	test_framework.assert_approximately(test_hero.get_attack_interval(), attack_interval, 0.01, "Attack interval should be calculated correctly")
	
	# Test damage calculations with defense
	var attack_damage = 50
	var expected_damage_taken = max(1, attack_damage - test_hero.current_stats.defense)
	test_framework.assert_equal(test_hero.calculate_damage_taken(attack_damage), expected_damage_taken, "Damage taken should consider defense")
	
	print("✓ Stat calculation tests passed")

func create_test_hero() -> HeroBase:
	"""Helper function to create and setup a test hero"""
	if not hero_scene:
		hero_scene = Data.load_resource_safe("res://Scenes/heroes/phantom_spirit.tscn", "PackedScene")
	
	var hero = hero_scene.instantiate() as HeroBase
	if hero:
		test_scene.add_child(hero)
		hero.hero_type = "phantom_spirit"
		hero.setup_hero_data()
		hero.respawn_hero()  # Ensure hero is alive
	
	return hero

func cleanup():
	"""Clean up test resources"""
	if test_hero and is_instance_valid(test_hero):
		test_hero.queue_free()
	
	if test_scene and is_instance_valid(test_scene):
		test_scene.queue_free()
	
	if test_framework and is_instance_valid(test_framework):
		test_framework.queue_free()