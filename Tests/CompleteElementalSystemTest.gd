extends "res://Tests/TestBase.gd"

# Comprehensive test for all 5 elemental systems
class_name CompleteElementalSystemTest

func _ready():
	test_name = "Complete Elemental System Test"
	super._ready()

func run_test():
	print("Testing Complete Elemental System...")
	
	# Test 1: All element gems exist
	print("\nTest 1: Element Gem Validation")
	var elements = ["ice", "earth", "wind", "light", "shadow"]
	var gem_levels = {
		"ice": ["ice_basic", "ice_intermediate", "ice_advanced"],
		"earth": ["earth_basic", "earth_intermediate", "earth_advanced"],
		"wind": ["wind_basic", "wind_intermediate", "wind_advanced"],
		"light": ["light_basic", "light_intermediate", "light_advanced"],
		"shadow": ["暗影宝石 1级", "暗影之心 2级", "暗影之魂 3级"]
	}
	
	var all_gems_found = true
	for element in elements:
		var gems = gem_levels[element]
		var gems_found = 0
		
		for gem in gems:
			if Data.tower_skills.has(gem):
				gems_found += 1
				print("  [OK] Found gem: ", gem)
			else:
				print("  [FAIL] Missing gem: ", gem)
				all_gems_found = false
		
		print("  ", element, ": ", gems_found, "/", gems.size(), " gems")
	
	if all_gems_found:
		test_results.append("Element Gems: PASS")
	else:
		test_results.append("Element Gems: FAIL")
		return false
	
	# Test 2: Status effects for all elements
	print("\nTest 2: Status Effect Validation")
	var expected_effects = {
		"ice": ["frost_debuff", "freeze"],
		"earth": ["weight_debuff", "armor_break_debuff", "petrify"],
		"wind": ["imbalance_debuff", "knockback", "silence"],
		"light": ["blind", "purify", "judgment"],
		"shadow": ["corrosion", "fear", "life_drain"]
	}
	
	var status_effect_system = get_node_or_null("/root/StatusEffectSystem")
	if not status_effect_system:
		print("  [FAIL] StatusEffectSystem not found")
		test_results.append("Status Effects: FAIL")
		return false
	
	var all_effects_found = true
	for element in elements:
		var effects = expected_effects[element]
		var effects_found = 0
		
		for effect in effects:
			if status_effect_system.has_method("apply_" + effect):
				effects_found += 1
				print("  [OK] Found effect: ", effect)
			else:
				print("  [FAIL] Missing effect: ", effect)
				all_effects_found = false
		
		print("  ", element, ": ", effects_found, "/", effects.size(), " effects")
	
	if all_effects_found:
		test_results.append("Status Effects: PASS")
	else:
		test_results.append("Status Effects: FAIL")
		return false
	
	# Test 3: Gem effect system integration
	print("\nTest 3: GemEffectSystem Integration")
	var gem_effect_system = get_node_or_null("/root/GemEffectSystem")
	if not gem_effect_system:
		print("  [FAIL] GemEffectSystem not found")
		test_results.append("GemEffectSystem: FAIL")
		return false
	
	var expected_methods = [
		"apply_frost", "apply_freeze",
		"apply_weight", "apply_armor_break", "apply_petrify",
		"apply_imbalance", "apply_knockback", "apply_silence",
		"apply_blind", "apply_purify", "apply_judgment",
		"apply_corrosion", "apply_fear", "apply_life_drain"
	]
	
	var methods_found = 0
	for method in expected_methods:
		if gem_effect_system.has_method(method):
			methods_found += 1
			print("  [OK] Found method: ", method)
		else:
			print("  [FAIL] Missing method: ", method)
	
	if methods_found >= expected_methods.size() * 0.9:
		test_results.append("GemEffectSystem: PASS")
		print("  GemEffectSystem integration: ", methods_found, "/", expected_methods.size(), " methods")
	else:
		test_results.append("GemEffectSystem: FAIL")
		return false
	
	# Test 4: Enemy effect support
	print("\nTest 4: Enemy Effect Support")
	var enemy_scene = preload("res://Scenes/enemies/enemy_mover.tscn")
	var test_enemy = enemy_scene.instantiate()
	add_child(test_enemy)
	
	var enemy_methods = [
		"apply_speed_modifier", "remove_speed_modifier",
		"set_frost_stacks", "set_frozen", "get_frost_stacks", "get_is_frozen",
		"set_weight_stacks", "set_petrified", "get_weight_stacks", "get_is_petrified",
		"set_imbalance_stacks", "set_knocked_back", "set_silenced", 
		"get_imbalance_stacks", "get_is_knocked_back", "get_is_silenced",
		"set_blind", "set_purified", "set_judgment",
		"get_blind_stacks", "get_is_purified", "get_is_judged",
		"set_corrosion_stacks", "set_fear", "set_life_drain",
		"get_corrosion_stacks", "get_is_fearing", "get_is_life_draining"
	]
	
	var enemy_methods_found = 0
	for method in enemy_methods:
		if test_enemy.has_method(method):
			enemy_methods_found += 1
		else:
			print("  [WARN] Enemy missing method: ", method)
	
	test_enemy.queue_free()
	
	if enemy_methods_found >= enemy_methods.size() * 0.8:
		test_results.append("Enemy Effects: PASS")
		print("  Enemy effect support: ", enemy_methods_found, "/", enemy_methods.size(), " methods")
	else:
		test_results.append("Enemy Effects: FAIL")
		return false
	
	# Test 5: Element system integration
	print("\nTest 5: Element System Integration")
	var element_system = get_node_or_null("/root/ElementSystem")
	if not element_system:
		print("  [FAIL] ElementSystem not found")
		test_results.append("ElementSystem: FAIL")
		return false
	
	# Check if all elements are defined
	var element_colors = {
		"ice": Color.CYAN,
		"earth": Color.BROWN,
		"wind": Color.GREEN,
		"light": Color.YELLOW,
		"shadow": Color.PURPLE
	}
	
	var elements_defined = 0
	for element in elements:
		var color = element_system.get_element_color(element)
		if color != Color.WHITE:
			elements_defined += 1
			print("  [OK] Element defined: ", element)
		else:
			print("  [FAIL] Element not defined: ", element)
	
	if elements_defined == elements.size():
		test_results.append("ElementSystem: PASS")
	else:
		test_results.append("ElementSystem: FAIL")
		return false
	
	# Test 6: Tower integration
	print("\nTest 6: Tower Integration")
	var turret_scene = preload("res://Scenes/turrets/turretBase/turret_base.tscn")
	var test_turret = turret_scene.instantiate()
	add_child(test_turret)
	
	# Check if turret has elemental effect methods
	var turret_methods = [
		"_setup_frost_area_effect", "_setup_freeze_main_target_effect",
		"_setup_weight_effect", "_setup_armor_break_effect", "_setup_petrify_effect",
		"_setup_imbalance_effect", "_setup_knockback_effect", "_setup_silence_effect",
		"_setup_blind_effect", "_setup_purify_effect", "_setup_judgment_effect",
		"_setup_corrosion_effect", "_setup_fear_effect", "_setup_life_drain_effect"
	]
	
	var turret_methods_found = 0
	for method in turret_methods:
		if test_turret.has_method(method):
			turret_methods_found += 1
		else:
			print("  [WARN] Turret missing method: ", method)
	
	test_turret.queue_free()
	
	if turret_methods_found >= turret_methods.size() * 0.8:
		test_results.append("Tower Integration: PASS")
		print("  Tower effect methods: ", turret_methods_found, "/", turret_methods.size(), " methods")
	else:
		test_results.append("Tower Integration: FAIL")
		return false
	
	print("\n[SUCCESS] Complete Elemental System Test Passed!")
	test_results.append("Complete Elemental System: PASS")
	return true