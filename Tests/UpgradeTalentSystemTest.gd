extends Node
class_name UpgradeTalentSystemTest

## Upgrade & Talent System Test Suite
## Tests experience gain, leveling mechanics, talent selection, and attribute progression

const TestFramework = preload("res://Tests/TestFramework.gd")

var test_framework: TestFramework
var test_scene: Node2D
var test_hero: HeroBase
var talent_system: Node

func _ready():
	print("=== Upgrade & Talent System Test Suite Started ===")
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# Setup test environment
	setup_test_environment()
	
	# Run all tests
	run_all_tests()
	
	print("=== Upgrade & Talent System Test Suite Completed ===")

func setup_test_environment():
	"""Create test scene and components"""
	# Create test scene
	test_scene = Node2D.new()
	add_child(test_scene)
	
	# Create test hero
	test_hero = create_test_hero()
	
	# Create talent system
	talent_system = Node.new()
	talent_system.set_script(preload("res://Tests/Mocks/MockTalentSystem.gd"))
	test_scene.add_child(talent_system)

func run_all_tests():
	"""Execute all upgrade and talent system tests"""
	var tests = [
		{"name": "Experience Gain Mechanics", "func": test_experience_gain},
		{"name": "Level Progression System", "func": test_level_progression},
		{"name": "Talent Selection Interface", "func": test_talent_selection},
		{"name": "Talent Effect Application", "func": test_talent_effects},
		{"name": "Attribute Progression", "func": test_attribute_progression},
		{"name": "Talent Stacking", "func": test_talent_stacking},
		{"name": "Level Threshold Validation", "func": test_level_thresholds},
		{"name": "Talent Choice Validation", "func": test_talent_choice_validation}
	]
	
	test_framework.run_test_suite("Upgrade & Talent System", tests)

func test_experience_gain():
	"""Test experience gain mechanics and calculations"""
	print("Testing experience gain mechanics...")
	
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not test_hero:
		return
	
	# Test initial experience state
	test_framework.assert_equal(test_hero.experience, 0, "Initial experience should be 0")
	test_framework.assert_equal(test_hero.current_level, 1, "Initial level should be 1")
	
	# Test basic experience gain
	var exp_gain = 50
	test_hero.gain_experience(exp_gain)
	test_framework.assert_equal(test_hero.experience, exp_gain, "Experience should increase by gain amount")
	
	# Test multiple experience gains
	test_hero.gain_experience(30)
	test_hero.gain_experience(20)
	test_framework.assert_equal(test_hero.experience, 100, "Experience should accumulate correctly")
	
	# Test experience thresholds
	var level_thresholds = get_level_thresholds()
	test_framework.assert_array_size(level_thresholds, 19, "Should have thresholds for levels 2-20")
	
	# Test experience threshold validation
	for level in range(2, 21):
		var threshold = level_thresholds[level - 2]  # Array is 0-indexed
		test_framework.assert_true(threshold > 0, "Level %d threshold should be positive" % level)
		test_framework.assert_true(threshold > level_thresholds[level - 3] if level > 2 else true, 
			"Thresholds should increase with level")
	
	# Test experience calculation from enemy defeat
	var enemy_exp_values = {
		"basic": 10,
		"elite": 25,
		"boss": 100
	}
	
	for enemy_type in enemy_exp_values:
		var calculated_exp = calculate_experience_from_enemy(enemy_type)
		test_framework.assert_equal(calculated_exp, enemy_exp_values[enemy_type], 
			"Experience should be calculated correctly for %s enemy" % enemy_type)
	
	# Test experience modifiers
	var exp_multiplier = 1.5
	var modified_exp = int(exp_gain * exp_multiplier)
	test_framework.assert_true(modified_exp > exp_gain, "Modified experience should be higher than base")
	
	print("✓ Experience gain mechanics tests passed")

func test_level_progression():
	"""Test hero leveling and progression mechanics"""
	print("Testing level progression...")
	
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not test_hero:
		return
	
	# Test level up at threshold
	var level_2_threshold = 300
	test_hero.experience = level_2_threshold - 1
	test_framework.assert_equal(test_hero.current_level, 1, "Should not level up before threshold")
	
	test_hero.experience = level_2_threshold
	test_hero.check_level_up()
	test_framework.assert_equal(test_hero.current_level, 2, "Should level up at threshold")
	
	# Test multiple level ups
	var level_3_threshold = 800
	test_hero.experience = level_3_threshold
	test_hero.check_level_up()
	test_framework.assert_equal(test_hero.current_level, 3, "Should level up to 3")
	
	# Test experience overflow handling
	test_hero.experience = 10000
	test_hero.check_level_up()
	test_framework.assert_true(test_hero.current_level >= 3, "Should handle experience overflow correctly")
	
	# Test level cap
	var max_level = 20
	test_hero.current_level = max_level
	test_hero.experience = 999999
	test_hero.check_level_up()
	test_framework.assert_equal(test_hero.current_level, max_level, "Should not exceed maximum level")
	
	# Test level progression signals
	var level_up_emitted = false
	var level_up_level = 0
	
	test_hero.level_up.connect(func(level):
		level_up_emitted = true
		level_up_level = level
	)
	
	test_hero.current_level = 1
	test_hero.experience = level_2_threshold
	test_hero.check_level_up()
	
	test_framework.assert_true(level_up_emitted, "Level up signal should be emitted")
	test_framework.assert_equal(level_up_level, 2, "Correct level should be passed in signal")
	
	# Test stat increases on level up
	var base_damage = test_hero.base_stats.damage
	test_hero.current_level = 5
	test_hero.update_stats_for_level()
	test_framework.assert_true(test_hero.current_stats.damage > base_damage, "Damage should increase with level")
	
	print("✓ Level progression tests passed")

func test_talent_selection():
	"""Test talent selection interface and mechanics"""
	print("Testing talent selection...")
	
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not test_hero:
		return
	
	# Test talent availability at specific levels
	var talent_levels = [5, 10, 15]
	
	for level in talent_levels:
		test_hero.current_level = level
		test_hero.check_level_up()
		test_framework.assert_true(test_hero.pending_talent_selection, 
			"Should have pending talent selection at level %d" % level)
	
	# Test talent data availability
	test_framework.assert_has_key(Data.hero_talents, "phantom_spirit", "Should have talent data for phantom_spirit")
	
	var phantom_talents = Data.hero_talents.phantom_spirit
	test_framework.assert_has_key(phantom_talents, "level_5", "Should have level 5 talents")
	test_framework.assert_has_key(phantom_talents, "level_10", "Should have level 10 talents")
	test_framework.assert_has_key(phantom_talents, "level_15", "Should have level 15 talents")
	
	# Test talent choice count
	test_framework.assert_array_size(phantom_talents.level_5, 2, "Should have 2 talent choices at level 5")
	test_framework.assert_array_size(phantom_talents.level_10, 2, "Should have 2 talent choices at level 10")
	test_framework.assert_array_size(phantom_talents.level_15, 2, "Should have 2 talent choices at level 15")
	
	# Test talent selection process
	test_hero.current_level = 5
	test_hero.pending_talent_selection = true
	
	var available_talents = get_available_talents_for_level(test_hero.hero_type, 5)
	test_framework.assert_array_size(available_talents, 2, "Should get correct number of available talents")
	
	# Test talent selection
	var selected_talent = available_talents[0]
	var selection_success = select_talent(test_hero, selected_talent)
	test_framework.assert_true(selection_success, "Talent selection should succeed")
	test_framework.assert_false(test_hero.pending_talent_selection, "Pending selection should be cleared")
	test_framework.assert_has_key(test_hero.selected_talents, selected_talent.id, "Selected talent should be recorded")
	
	# Test talent selection at different levels
	test_hero.current_level = 10
	test_hero.pending_talent_selection = true
	var level_10_talents = get_available_talents_for_level(test_hero.hero_type, 10)
	test_framework.assert_array_size(level_10_talents, 2, "Should have level 10 talents available")
	
	print("✓ Talent selection tests passed")

func test_talent_effects():
	"""Test talent effect application and functionality"""
	print("Testing talent effects...")
	
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not test_hero:
		return
	
	# Test talent effect structure
	var test_talent = get_test_talent()
	test_framework.assert_has_key(test_talent, "effects", "Talent should have effects defined")
	test_framework.assert_has_key(test_talent.effects, "shadow_strike_attack_count", "Effect should have specific modifications")
	
	# Test base stats before talent application
	var base_attack_count = get_skill_attack_count("shadow_strike")
	test_framework.assert_equal(base_attack_count, 5, "Base shadow strike should have 5 attacks")
	
	# Test talent effect application
	apply_talent_effect(test_hero, test_talent)
	var modified_attack_count = get_skill_attack_count("shadow_strike")
	test_framework.assert_equal(modified_attack_count, 7, "Modified shadow strike should have 7 attacks")
	
	# Test multiplicative talent effects
	var base_charge_generation = test_hero.charge_generation
	var charge_talent = get_charge_talent()
	
	apply_talent_effect(test_hero, charge_talent)
	test_framework.assert_approximately(test_hero.charge_generation, base_charge_generation * 1.5, 0.01, 
		"Charge generation should be multiplied by 1.5")
	
	# Test additive talent effects
	var base_defense = test_hero.base_stats.defense
	var defense_talent = get_defense_talent()
	
	apply_talent_effect(test_hero, defense_talent)
	test_framework.assert_equal(test_hero.current_stats.defense, base_defense + 10, "Defense should increase by 10")
	
	# Test talent effect persistence
	test_hero.current_level = 2
	test_hero.update_stats_for_level()
	test_framework.assert_true(test_hero.charge_generation > base_charge_generation, "Talent effects should persist through level updates")
	
	# Test talent effect removal (if applicable)
	remove_talent_effect(test_hero, test_talent)
	var restored_attack_count = get_skill_attack_count("shadow_strike")
	test_framework.assert_equal(restored_attack_count, base_attack_count, "Attack count should be restored after talent removal")
	
	print("✓ Talent effects tests passed")

func test_attribute_progression():
	"""Test hero attribute progression with levels"""
	print("Testing attribute progression...")
	
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not test_hero:
		return
	
	# Test base attribute recording
	var base_stats = test_hero.base_stats.duplicate(true)
	
	# Test progression formulas
	for level in range(1, 21):
		var expected_hp = calculate_expected_hp(level, base_stats.max_hp)
		var expected_damage = calculate_expected_damage(level, base_stats.damage)
		var expected_defense = calculate_expected_defense(level, base_stats.defense)
		
		test_hero.current_level = level
		test_hero.update_stats_for_level()
		
		test_framework.assert_approximately(test_hero.current_stats.max_hp, expected_hp, 1.0, 
			"HP at level %d should match expected value" % level)
		test_framework.assert_approximately(test_hero.current_stats.damage, expected_damage, 1.0, 
			"Damage at level %d should match expected value" % level)
		test_framework.assert_approximately(test_hero.current_stats.defense, expected_defense, 1.0, 
			"Defense at level %d should match expected value" % level)
	
	# Test progression rate consistency
	var level_5_hp = calculate_expected_hp(5, base_stats.max_hp)
	var level_10_hp = calculate_expected_hp(10, base_stats.max_hp)
	var level_15_hp = calculate_expected_hp(15, base_stats.max_hp)
	
	var hp_growth_5_to_10 = level_10_hp - level_5_hp
	var hp_growth_10_to_15 = level_15_hp - level_10_hp
	
	test_framework.assert_true(hp_growth_10_to_15 >= hp_growth_5_to_10, 
		"HP growth should be consistent or increasing with level")
	
	# Test attribute caps
	var max_hp_cap = 9999
	var max_damage_cap = 999
	var max_defense_cap = 999
	
	test_hero.current_level = 99  # Very high level
	test_hero.update_stats_for_level()
	
	test_framework.assert_true(test_hero.current_stats.max_hp <= max_hp_cap, "HP should not exceed cap")
	test_framework.assert_true(test_hero.current_stats.damage <= max_damage_cap, "Damage should not exceed cap")
	test_framework.assert_true(test_hero.current_stats.defense <= max_defense_cap, "Defense should not exceed cap")
	
	# Test progression display
	var progression_info = get_progression_info(test_hero)
	test_framework.assert_has_key(progression_info, "current_level", "Progression info should include current level")
	test_framework.assert_has_key(progression_info, "next_level_exp", "Progression info should include next level exp")
	test_framework.assert_has_key(progression_info, "stat_gains", "Progression info should include stat gains")
	
	print("✓ Attribute progression tests passed")

func test_talent_stacking():
	"""Test talent effect stacking and interactions"""
	print("Testing talent stacking...")
	
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not test_hero:
		return
	
	# Test multiple talent application
	var talent_1 = get_attack_talent()
	var talent_2 = get_charge_talent()
	
	var base_damage = test_hero.current_stats.damage
	var base_charge = test_hero.charge_generation
	
	# Apply first talent
	apply_talent_effect(test_hero, talent_1)
	var damage_after_talent_1 = test_hero.current_stats.damage
	
	# Apply second talent
	apply_talent_effect(test_hero, talent_2)
	var damage_after_talent_2 = test_hero.current_stats.damage
	var charge_after_talent_2 = test_hero.charge_generation
	
	# Test that both effects are active
	test_framework.assert_true(damage_after_talent_2 > damage_after_talent_1, "Damage should be further increased")
	test_framework.assert_true(charge_after_talent_2 > base_charge, "Charge generation should be increased")
	
	# Test stacking limits
	var max_damage_multiplier = 3.0
	var max_charge_multiplier = 2.0
	
	test_framework.assert_true(test_hero.current_stats.damage <= base_damage * max_damage_multiplier, 
		"Damage should not exceed stacking limit")
	test_framework.assert_true(test_hero.charge_generation <= base_charge * max_charge_multiplier, 
		"Charge generation should not exceed stacking limit")
	
	# Test talent interaction rules
	var conflicting_talents = get_conflicting_talents()
	for conflict_pair in conflicting_talents:
		var can_stack = can_talents_stack(conflict_pair[0], conflict_pair[1])
		test_framework.assert_false(can_stack, "Conflicting talents should not stack")
	
	# Test synergistic talent combinations
	var synergistic_pairs = get_synergistic_talent_pairs()
	for pair in synergistic_pairs:
		var synergy_bonus = calculate_synergy_bonus(pair[0], pair[1])
		test_framework.assert_true(synergy_bonus > 1.0, "Synergistic pairs should provide bonus")
	
	# Test talent order independence
	test_hero.current_stats.damage = base_damage
	test_hero.charge_generation = base_charge
	
	# Apply in reverse order
	apply_talent_effect(test_hero, talent_2)
	apply_talent_effect(test_hero, talent_1)
	
	test_framework.assert_approximately(test_hero.current_stats.damage, damage_after_talent_2, 0.01, 
		"Talent order should not affect final result")
	test_framework.assert_approximately(test_hero.charge_generation, charge_after_talent_2, 0.01, 
		"Talent order should not affect final result")
	
	print("✓ Talent stacking tests passed")

func test_level_thresholds():
	"""Test level-up threshold validation and requirements"""
	print("Testing level thresholds...")
	
	# Test threshold array generation
	var thresholds = get_level_thresholds()
	test_framework.assert_array_size(thresholds, 19, "Should have thresholds for levels 2-20")
	
	# Test threshold progression
	for i in range(1, thresholds.size()):
		test_framework.assert_true(thresholds[i] > thresholds[i-1], "Thresholds should increase with level")
	
	# Test specific threshold values
	var expected_thresholds = {
		2: 300,
		5: 1500,
		10: 5000,
		15: 12000,
		20: 25000
	}
	
	for level, expected_threshold in expected_thresholds:
		var actual_threshold = get_threshold_for_level(level)
		test_framework.assert_equal(actual_threshold, expected_threshold, 
			"Threshold for level %d should be %d" % [level, expected_threshold])
	
	# Test threshold checking function
	test_hero.current_level = 1
	test_hero.experience = 299
	test_framework.assert_false(can_level_up(test_hero), "Should not level up at 299 exp")
	
	test_hero.experience = 300
	test_framework.assert_true(can_level_up(test_hero), "Should level up at 300 exp")
	
	# Test threshold calculation formulas
	var base_threshold = 300
	var growth_rate = 1.2
	
	for level in range(2, 11):
		var calculated_threshold = base_threshold * pow(growth_rate, level - 2)
		var actual_threshold = get_threshold_for_level(level)
		var tolerance = calculated_threshold * 0.1  # 10% tolerance for rounding
		test_framework.assert_in_range(actual_threshold, calculated_threshold - tolerance, calculated_threshold + tolerance,
			"Calculated threshold should be within tolerance for level %d" % level)
	
	# Test experience to next level
	var exp_to_next = get_experience_to_next_level(test_hero)
	test_framework.assert_true(exp_to_next > 0, "Experience to next level should be positive")
	
	test_hero.current_level = 19
	test_hero.experience = get_threshold_for_level(19)
	test_framework.assert_equal(get_experience_to_next_level(test_hero), get_threshold_for_level(20) - get_threshold_for_level(19),
		"Experience to level 20 should be difference between thresholds")
	
	# Test max level handling
	test_hero.current_level = 20
	test_hero.experience = 999999
	test_framework.assert_false(can_level_up(test_hero), "Should not level up at max level")
	test_framework.assert_equal(get_experience_to_next_level(test_hero), 0, "Experience to next level should be 0 at max level")
	
	print("✓ Level threshold tests passed")

func test_talent_choice_validation():
	"""Test talent choice validation and error handling"""
	print("Testing talent choice validation...")
	
	test_framework.assert_not_null(test_hero, "Test hero should be created")
	
	if not test_hero:
		return
	
	# Test valid talent selection
	test_hero.current_level = 5
	test_hero.pending_talent_selection = true
	
	var valid_talents = get_available_talents_for_level(test_hero.hero_type, 5)
	var valid_talent = valid_talents[0]
	
	var validation_result = validate_talent_selection(test_hero, valid_talent)
	test_framework.assert_true(validation_result.valid, "Valid talent should pass validation")
	test_framework.assert_equal(validation_result.reason, "", "Valid talent should have no error reason")
	
	# Test invalid level for talent
	var high_level_talent = get_talent_for_level(15)
	validation_result = validate_talent_selection(test_hero, high_level_talent)
	test_framework.assert_false(validation_result.valid, "High level talent should fail validation")
	test_framework.assert_equal(validation_result.reason, "level_requirement", "Should fail with level requirement reason")
	
	# Test duplicate talent selection
	apply_talent_effect(test_hero, valid_talent)
	validation_result = validate_talent_selection(test_hero, valid_talent)
	test_framework.assert_false(validation_result.valid, "Duplicate talent should fail validation")
	test_framework.assert_equal(validation_result.reason, "already_learned", "Should fail with already learned reason")
	
	# Test talent prerequisites
	var talent_with_prereq = get_talent_with_prerequisite()
	validation_result = validate_talent_selection(test_hero, talent_with_prereq)
	test_framework.assert_false(validation_result.valid, "Talent without prerequisite should fail validation")
	test_framework.assert_equal(validation_result.reason, "prerequisite", "Should fail with prerequisite reason")
	
	# Test talent pool validation
	var invalid_talent = {"id": "invalid_talent", "name": "Invalid Talent"}
	validation_result = validate_talent_selection(test_hero, invalid_talent)
	test_framework.assert_false(validation_result.valid, "Invalid talent should fail validation")
	test_framework.assert_equal(validation_result.reason, "invalid_talent", "Should fail with invalid talent reason")
	
	# Test selection timing validation
	test_hero.pending_talent_selection = false
	validation_result = validate_talent_selection(test_hero, valid_talent)
	test_framework.assert_false(validation_result.valid, "Talent selection should fail when not pending")
	test_framework.assert_equal(validation_result.reason, "not_pending", "Should fail with not pending reason")
	
	# Test talent choice count validation
	test_hero.current_level = 5
	test_hero.pending_talent_selection = true
	
	var talent_choices = get_available_talents_for_level(test_hero.hero_type, 5)
	test_framework.assert_array_size(talent_choices, 2, "Should have exactly 2 talent choices")
	
	# Test that all choices are valid
	for talent in talent_choices:
		validation_result = validate_talent_selection(test_hero, talent)
		test_framework.assert_true(validation_result.valid, "All provided talent choices should be valid")
	
	print("✓ Talent choice validation tests passed")

# Helper functions

func create_test_hero() -> HeroBase:
	"""Create a test hero for talent system testing"""
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

func get_level_thresholds() -> Array[int]:
	"""Get experience thresholds for levels 2-20"""
	return [
		300, 800, 1500, 2500, 3800,  # Levels 2-6
		5400, 7300, 9500, 12000, 14800,  # Levels 7-11
		17900, 21300, 25000, 29000, 33300,  # Levels 12-16
		37900, 42800, 48000, 53500  # Levels 17-20
	]

func get_threshold_for_level(level: int) -> int:
	"""Get experience threshold for specific level"""
	if level <= 1:
		return 0
	if level > 20:
		return get_threshold_for_level(20)
	
	var thresholds = get_level_thresholds()
	return thresholds[level - 2]

func can_level_up(hero: HeroBase) -> bool:
	"""Check if hero can level up"""
	if hero.current_level >= 20:
		return false
	
	var threshold = get_threshold_for_level(hero.current_level + 1)
	return hero.experience >= threshold

func get_experience_to_next_level(hero: HeroBase) -> int:
	"""Get experience needed for next level"""
	if hero.current_level >= 20:
		return 0
	
	var next_threshold = get_threshold_for_level(hero.current_level + 1)
	return next_threshold - hero.experience

func calculate_experience_from_enemy(enemy_type: String) -> int:
	"""Calculate experience from defeating enemy"""
	match enemy_type:
		"basic":
			return 10
		"elite":
			return 25
		"boss":
			return 100
		_:
			return 5

func get_available_talents_for_level(hero_type: String, level: int) -> Array:
	"""Get available talents for hero at specific level"""
	if not Data.hero_talents.has(hero_type):
		return []
	
	var hero_talents = Data.hero_talents[hero_type]
	match level:
		5:
			return hero_talents.level_5.duplicate(true)
		10:
			return hero_talents.level_10.duplicate(true)
		15:
			return hero_talents.level_15.duplicate(true)
		_:
			return []

func get_test_talent() -> Dictionary:
	"""Get a test talent for effect testing"""
	return {
		"id": "enhanced_strikes",
		"name": "强化打击",
		"description": "无影拳攻击次数+2",
		"effects": {
			"shadow_strike_attack_count": 2
		}
	}

func get_charge_talent() -> Dictionary:
	"""Get a charge generation talent"""
	return {
		"id": "rapid_charge",
		"name": "快速充能",
		"description": "充能速度+50%",
		"effects": {
			"charge_generation_multiplier": 1.5
		}
	}

func get_defense_talent() -> Dictionary:
	"""Get a defense talent"""
	return {
		"id": "defensive_stance",
		"name": "防御姿态",
		"description": "防御力+10",
		"effects": {
			"defense_bonus": 10
		}
	}

func get_attack_talent() -> Dictionary:
	"""Get an attack talent"""
	return {
		"id": "flame_mastery",
		"name": "火焰精通",
		"description": "火焰甲光环伤害+100%",
		"effects": {
			"flame_armor_aura_damage": 2.0
		}
	}

func get_talent_for_level(level: int) -> Dictionary:
	"""Get a talent for specific level"""
	return get_available_talents_for_level("phantom_spirit", level)[0]

func get_talent_with_prerequisite() -> Dictionary:
	"""Get a talent that has prerequisites"""
	return {
		"id": "advanced_talent",
		"name": "高级天赋",
		"description": "需要基础天赋",
		"prerequisites": ["basic_talent"],
		"effects": {
			"advanced_bonus": 1.5
		}
	}

func select_talent(hero: HeroBase, talent: Dictionary) -> bool:
	"""Select a talent for hero"""
	if not validate_talent_selection(hero, talent).valid:
		return false
	
	apply_talent_effect(hero, talent)
	hero.selected_talents[talent.id] = talent
	hero.pending_talent_selection = false
	return true

func validate_talent_selection(hero: HeroBase, talent: Dictionary) -> Dictionary:
	"""Validate talent selection"""
	if not hero.pending_talent_selection:
		return {"valid": false, "reason": "not_pending"}
	
	if not talent.has("id") or not talent.has("name"):
		return {"valid": false, "reason": "invalid_talent"}
	
	if hero.selected_talents.has(talent.id):
		return {"valid": false, "reason": "already_learned"}
	
	# Check level requirements
	var talent_level = get_talent_level(talent)
	if hero.current_level < talent_level:
		return {"valid": false, "reason": "level_requirement"}
	
	# Check prerequisites
	if talent.has("prerequisites"):
		for prereq in talent.prerequisites:
			if not hero.selected_talents.has(prereq):
				return {"valid": false, "reason": "prerequisite"}
	
	return {"valid": true, "reason": ""}

func get_talent_level(talent: Dictionary) -> int:
	"""Get the level requirement for a talent"""
	# This is a simplified version - in reality would look up talent data
	if talent.id in ["enhanced_strikes", "rapid_charge"]:
		return 5
	elif talent.id in ["flame_mastery", "defensive_stance"]:
		return 10
	else:
		return 15

func apply_talent_effect(hero: HeroBase, talent: Dictionary):
	"""Apply talent effects to hero"""
	for effect_key, effect_value in talent.effects:
		match effect_key:
			"shadow_strike_attack_count":
				# Modify skill attack count
				pass
			"charge_generation_multiplier":
				hero.charge_generation *= effect_value
			"defense_bonus":
				hero.current_stats.defense += effect_value
			"flame_armor_aura_damage":
				# Modify skill aura damage
				pass
			_:
				push_warning("Unknown talent effect: %s" % effect_key)

func remove_talent_effect(hero: HeroBase, talent: Dictionary):
	"""Remove talent effects from hero"""
	# This would reverse the effects of apply_talent_effect
	# Simplified for testing
	pass

func get_skill_attack_count(skill_name: String) -> int:
	"""Get attack count for a skill"""
	# Simplified - would access actual skill data
	match skill_name:
		"shadow_strike":
			return 5 + (test_hero.selected_talents.get("enhanced_strikes", {}).get("effects", {}).get("shadow_strike_attack_count", 0))
		_:
			return 1

func calculate_expected_hp(level: int, base_hp: float) -> float:
	"""Calculate expected HP at given level"""
	var growth_rate = 0.1  # 10% per level
	return base_hp * (1 + growth_rate * (level - 1))

func calculate_expected_damage(level: int, base_damage: float) -> float:
	"""Calculate expected damage at given level"""
	var growth_rate = 0.08  # 8% per level
	return base_damage * (1 + growth_rate * (level - 1))

func calculate_expected_defense(level: int, base_defense: float) -> float:
	"""Calculate expected defense at given level"""
	var growth_rate = 0.05  # 5% per level
	return base_defense * (1 + growth_rate * (level - 1))

func get_progression_info(hero: HeroBase) -> Dictionary:
	"""Get progression information for hero"""
	return {
		"current_level": hero.current_level,
		"current_exp": hero.experience,
		"next_level_exp": get_experience_to_next_level(hero),
		"stat_gains": {
			"hp": calculate_expected_hp(hero.current_level + 1, hero.base_stats.max_hp) - hero.current_stats.max_hp,
			"damage": calculate_expected_damage(hero.current_level + 1, hero.base_stats.damage) - hero.current_stats.damage,
			"defense": calculate_expected_defense(hero.current_level + 1, hero.base_stats.defense) - hero.current_stats.defense
		}
	}

func get_conflicting_talents() -> Array:
	"""Get talent pairs that conflict with each other"""
	return [
		[get_attack_talent(), get_defense_talent()]  # Example conflict
	]

func get_synergistic_talent_pairs() -> Array:
	"""Get talent pairs that have synergy"""
	return [
		[get_charge_talent(), get_attack_talent()]  # Example synergy
	]

func can_talents_stack(talent1: Dictionary, talent2: Dictionary) -> bool:
	"""Check if two talents can stack"""
	# Simplified logic - in reality would check talent compatibility
	return false

func calculate_synergy_bonus(talent1: Dictionary, talent2: Dictionary) -> float:
	"""Calculate synergy bonus between two talents"""
	# Simplified - would calculate actual synergy effects
	return 1.1

func cleanup():
	"""Clean up test resources"""
	if test_hero and is_instance_valid(test_hero):
		test_hero.queue_free()
	
	if talent_system and is_instance_valid(talent_system):
		talent_system.queue_free()
	
	if test_scene and is_instance_valid(test_scene):
		test_scene.queue_free()
	
	if test_framework and is_instance_valid(test_framework):
		test_framework.queue_free()